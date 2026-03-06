import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import 'login_view.dart';

enum TodoSortOption {
  newestAdded,
  oldestAdded,
  recentlyUpdated,
  dueSoon,
  titleAZ,
  titleZA,
  completedFirst,
  incompleteFirst,
}

enum TodoFilterOption {
  all,
  completed,
  incomplete,
}

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  final TextEditingController _searchController = TextEditingController();
  TodoSortOption _sortOption = TodoSortOption.newestAdded;
  TodoFilterOption _filterOption = TodoFilterOption.all;
  bool _dashboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      if (mounted) {
        setState(() {
          _dashboardVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    final auth = context.read<AuthViewModel>();
    final todoVM = context.read<TodoViewModel>();
    final user = auth.currentUser;
    if (user != null) {
      todoVM.loadTodos(user.email);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');

    int hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$year-$month-$day  $hour:$minute $suffix';
  }

  String _formatDueDate(DateTime? dt) {
    if (dt == null) return 'No due date';
    return _formatDateTime(dt);
  }

  String _sortLabel(TodoSortOption option) {
    switch (option) {
      case TodoSortOption.newestAdded:
        return 'Newest';
      case TodoSortOption.oldestAdded:
        return 'Oldest';
      case TodoSortOption.recentlyUpdated:
        return 'Updated';
      case TodoSortOption.dueSoon:
        return 'Due Soon';
      case TodoSortOption.titleAZ:
        return 'A-Z';
      case TodoSortOption.titleZA:
        return 'Z-A';
      case TodoSortOption.completedFirst:
        return 'Done First';
      case TodoSortOption.incompleteFirst:
        return 'Pending First';
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      case 'Low':
        return Colors.lightGreenAccent;
      default:
        return Colors.white70;
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dueStatusText(TodoModel todo) {
    if (todo.completed) return 'Completed';
    if (todo.dueDate == null) return 'No Due Date';

    final now = DateTime.now();
    final today = _dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = _dateOnly(todo.dueDate!);

    if (todo.dueDate!.isBefore(now)) return 'Overdue';
    if (dueDay == today) return 'Due Today';
    if (dueDay == tomorrow) return 'Due Tomorrow';
    return 'Upcoming';
  }

  Color _dueStatusColor(TodoModel todo) {
    final status = _dueStatusText(todo);
    switch (status) {
      case 'Overdue':
        return Colors.redAccent;
      case 'Due Today':
        return Colors.deepOrangeAccent;
      case 'Due Tomorrow':
        return Colors.amberAccent;
      case 'Upcoming':
        return Constants.dsTeal;
      case 'Completed':
        return Colors.lightGreenAccent;
      case 'No Due Date':
      default:
        return Colors.white70;
    }
  }

  List<TodoModel> _applySearchFilterAndSort(
    List<TodoModel> todos,
    TodoViewModel todoVM,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = todos.where((todo) {
      final title = todo.title.toLowerCase();
      final note = todoVM.decryptNoteForUi(todo).toLowerCase();

      final matchesSearch =
          query.isEmpty || title.contains(query) || note.contains(query);

      bool matchesFilter = true;
      switch (_filterOption) {
        case TodoFilterOption.all:
          matchesFilter = true;
          break;
        case TodoFilterOption.completed:
          matchesFilter = todo.completed;
          break;
        case TodoFilterOption.incomplete:
          matchesFilter = !todo.completed;
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    switch (_sortOption) {
      case TodoSortOption.newestAdded:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TodoSortOption.oldestAdded:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TodoSortOption.recentlyUpdated:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case TodoSortOption.dueSoon:
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TodoSortOption.titleAZ:
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case TodoSortOption.titleZA:
        filtered.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case TodoSortOption.completedFirst:
        filtered.sort((a, b) {
          if (a.completed == b.completed) {
            return b.updatedAt.compareTo(a.updatedAt);
          }
          return a.completed ? -1 : 1;
        });
        break;
      case TodoSortOption.incompleteFirst:
        filtered.sort((a, b) {
          if (a.completed == b.completed) {
            return b.updatedAt.compareTo(a.updatedAt);
          }
          return a.completed ? 1 : -1;
        });
        break;
    }

    return filtered;
  }

  Future<DateTime?> _pickDueDateTime(DateTime? initialValue) async {
    final now = DateTime.now();
    final initialDate = initialValue ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (pickedDate == null) return initialValue;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue ?? now),
    );

    if (pickedTime == null) {
      return DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _showTodoFormDialog({TodoModel? existing}) async {
    final todoVM = context.read<TodoViewModel>();
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;
    if (user == null) return;

    final title = TextEditingController(text: existing?.title ?? '');
    final note = TextEditingController(
      text: existing == null ? '' : todoVM.decryptNoteForUi(existing),
    );

    DateTime? selectedDueDate = existing?.dueDate;
    String selectedPriority = existing?.priority ?? 'Medium';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'New To-Do' : 'Edit To-Do'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'Sensitive Note (Encrypted)',
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                    ),
                    items: TodoViewModel.priorities.map((priority) {
                      return DropdownMenuItem<String>(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedPriority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDueDate == null
                              ? 'No due date selected'
                              : 'Due: ${_formatDateTime(selectedDueDate!)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked =
                                await _pickDueDateTime(selectedDueDate);
                            if (picked == null) return;
                            setDialogState(() {
                              selectedDueDate = picked;
                            });
                          },
                          icon: const Icon(Icons.event),
                          label: const Text('Set Due Date'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selectedDueDate != null)
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedDueDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear due date',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(existing == null ? 'Save' : 'Update'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    bool success;
    if (existing == null) {
      success = await todoVM.addTodo(
        ownerEmail: user.email,
        title: title.text,
        notePlaintext: note.text,
        dueDate: selectedDueDate,
        priority: selectedPriority,
      );
    } else {
      success = await todoVM.updateTodo(
        ownerEmail: user.email,
        existing: existing,
        newTitle: title.text,
        newNotePlaintext: note.text,
        dueDate: selectedDueDate,
        priority: selectedPriority,
      );
    }

    if (!mounted) return;
    if (!success) {
      _snack(todoVM.error ?? 'Failed to save todo');
    }
  }

  Future<void> _confirmDelete(TodoModel todo) async {
    final todoVM = context.read<TodoViewModel>();
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;

    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete To-Do?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await todoVM.deleteTodo(
      ownerEmail: user.email,
      todoId: todo.id,
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out of CipherTask?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await context.read<AuthViewModel>().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  Future<void> _openDetails(TodoModel todo, String note) async {
    final action = await Navigator.of(context).push<_TodoDetailAction>(
      MaterialPageRoute(
        builder: (_) => _TodoDetailsPage(
          todo: todo,
          note: note,
          isOverdue: context.read<TodoViewModel>().isOverdue(todo),
          formatDateTime: _formatDateTime,
          priorityColor: _priorityColor(todo.priority),
          dueStatusText: _dueStatusText(todo),
          dueStatusColor: _dueStatusColor(todo),
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == _TodoDetailAction.edit) {
      await _showTodoFormDialog(existing: todo);
    } else if (action == _TodoDetailAction.delete) {
      await _confirmDelete(todo);
    }
  }

  Widget _buildFilterChip({
    required String label,
    required TodoFilterOption value,
  }) {
    final selected = _filterOption == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filterOption = value;
        });
      },
      selectedColor: Constants.dsCrimson.withOpacity(0.80),
      backgroundColor: Colors.white.withOpacity(0.06),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected
            ? Constants.dsCrimson.withOpacity(0.90)
            : Colors.white.withOpacity(0.10),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required int index,
  }) {
    return AnimatedSlide(
      offset: _dashboardVisible ? Offset.zero : const Offset(0.15, 0),
      duration: Duration(milliseconds: 350 + (index * 120)),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _dashboardVisible ? 1 : 0,
        duration: Duration(milliseconds: 350 + (index * 120)),
        curve: Curves.easeOut,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.96, end: 1),
          duration: Duration(milliseconds: 500 + (index * 120)),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 155,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: color.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.10),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _todoTile(TodoModel todo, String note, TodoViewModel todoVM) {
    final overdue = todoVM.isOverdue(todo);
    final dueStatusText = _dueStatusText(todo);
    final dueStatusColor = _dueStatusColor(todo);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: overdue
              ? Colors.redAccent.withOpacity(0.55)
              : Constants.dsTeal.withOpacity(0.25),
        ),
      ),
      child: ListTile(
        onTap: () => _openDetails(todo, note),
        leading: Checkbox(
          value: todo.completed,
          onChanged: (_) {
            final auth = context.read<AuthViewModel>();
            final user = auth.currentUser;
            if (user == null) return;

            context.read<TodoViewModel>().toggleCompleted(
                  ownerEmail: user.email,
                  todo: todo,
                );
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            decoration: todo.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.isEmpty ? '(No note)' : note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _statusChip(
                    label: todo.priority,
                    color: _priorityColor(todo.priority),
                  ),
                  _statusChip(
                    label: dueStatusText,
                    color: dueStatusColor,
                  ),
                  _statusChip(
                    label: _formatDueDate(todo.dueDate),
                    color: overdue ? Colors.redAccent : Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Added: ${_formatDateTime(todo.createdAt)}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final todoVM = context.watch<TodoViewModel>();
    final user = auth.currentUser;

    if (user == null) {
      return const LoginView();
    }

    final visibleTodos = _applySearchFilterAndSort(todoVM.todos, todoVM);

    return Scaffold(
      backgroundColor: Constants.dsBlack,
      appBar: AppBar(
        backgroundColor: Constants.dsBlack,
        foregroundColor: Colors.white,
        title: const Text('CipherTask • To-Dos'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: todoVM.isBusy ? null : () => _showTodoFormDialog(),
        backgroundColor: Constants.dsCrimson,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Constants.dsCrimson.withOpacity(0.30),
                      Constants.dsTeal.withOpacity(0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Signed in as: ${user.email}\nNotes are AES-256-GCM encrypted • DB is encrypted • Auto-lock: ${Constants.inactivityTimeoutSeconds}s',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: user.biometricsEnabled,
                      onChanged: (v) async {
                        await auth.setBiometricsEnabled(v);
                        if (auth.error != null) {
                          _snack(auth.error!);
                        }
                      },
                      activeColor: Constants.dsTeal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDashboardCard(
                      label: 'Total',
                      value: '${todoVM.totalCount}',
                      icon: Icons.list_alt,
                      color: Colors.white,
                      index: 0,
                    ),
                    const SizedBox(width: 10),
                    _buildDashboardCard(
                      label: 'Completed',
                      value: '${todoVM.completedCount}',
                      icon: Icons.check_circle,
                      color: Colors.lightGreenAccent,
                      index: 1,
                    ),
                    const SizedBox(width: 10),
                    _buildDashboardCard(
                      label: 'Pending',
                      value: '${todoVM.pendingCount}',
                      icon: Icons.pending_actions,
                      color: Colors.orangeAccent,
                      index: 2,
                    ),
                    const SizedBox(width: 10),
                    _buildDashboardCard(
                      label: 'Overdue',
                      value: '${todoVM.overdueCount}',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      index: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TodoSortOption>(
                          value: _sortOption,
                          isExpanded: true,
                          dropdownColor: Constants.dsBlack,
                          iconEnabledColor: Colors.white70,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _sortOption = value);
                          },
                          items: TodoSortOption.values.map((option) {
                            return DropdownMenuItem<TodoSortOption>(
                              value: option,
                              child: Text(
                                _sortLabel(option),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      value: TodoFilterOption.all,
                    ),
                    _buildFilterChip(
                      label: 'Completed',
                      value: TodoFilterOption.completed,
                    ),
                    _buildFilterChip(
                      label: 'Incomplete',
                      value: TodoFilterOption.incomplete,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing ${visibleTodos.length} to-do(s)',
                  style: const TextStyle(color: Colors.white54),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: visibleTodos.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.trim().isNotEmpty ||
                                  _filterOption != TodoFilterOption.all
                              ? 'No matching to-dos found.'
                              : 'No to-dos yet.\nTap + to add one.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: visibleTodos.length,
                        itemBuilder: (_, i) {
                          final todo = visibleTodos[i];
                          final note = todoVM.decryptNoteForUi(todo);
                          return _todoTile(todo, note, todoVM);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TodoDetailAction { edit, delete }

class _TodoDetailsPage extends StatelessWidget {
  final TodoModel todo;
  final String note;
  final bool isOverdue;
  final String Function(DateTime) formatDateTime;
  final Color priorityColor;
  final String dueStatusText;
  final Color dueStatusColor;

  const _TodoDetailsPage({
    required this.todo,
    required this.note,
    required this.isOverdue,
    required this.formatDateTime,
    required this.priorityColor,
    required this.dueStatusText,
    required this.dueStatusColor,
  });

  String get dueText =>
      todo.dueDate == null ? 'No due date' : formatDateTime(todo.dueDate!);

  Widget _detailChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.dsBlack,
      appBar: AppBar(
        backgroundColor: Constants.dsBlack,
        foregroundColor: Colors.white,
        title: const Text('Task Details'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, _TodoDetailAction.edit);
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context, _TodoDetailAction.delete);
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isOverdue
                    ? Colors.redAccent.withOpacity(0.45)
                    : Constants.dsTeal.withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    decoration:
                        todo.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _detailChip(
                      label: 'Priority: ${todo.priority}',
                      color: priorityColor,
                    ),
                    _detailChip(
                      label: dueStatusText,
                      color: dueStatusColor,
                    ),
                    _detailChip(
                      label: todo.completed ? 'Completed' : 'Incomplete',
                      color: todo.completed
                          ? Colors.lightGreenAccent
                          : Colors.white70,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sensitive Note',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    note.isEmpty ? '(No note)' : note,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  label: 'Due Date',
                  value: dueText,
                  valueColor: dueStatusColor,
                ),
                _DetailRow(
                  label: 'Added',
                  value: formatDateTime(todo.createdAt),
                ),
                _DetailRow(
                  label: 'Updated',
                  value: formatDateTime(todo.updatedAt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}