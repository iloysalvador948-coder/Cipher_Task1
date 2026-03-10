import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../widgets/todo_card.dart';
import 'profile_view.dart';
import 'todo_form_view.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum StatusFilter   { all, pending, completed, overdue }
enum PriorityFilter { all, high, medium, low }
enum SortOption     { newest, oldest, dueDate, priority, title }

extension StatusFilterLabel on StatusFilter {
  String get label => switch (this) {
        StatusFilter.all       => 'All',
        StatusFilter.pending   => 'Pending',
        StatusFilter.completed => 'Done',
        StatusFilter.overdue   => 'Overdue',
      };
}

extension PriorityFilterExt on PriorityFilter {
  String get label => switch (this) {
        PriorityFilter.all    => 'All',
        PriorityFilter.high   => 'High',
        PriorityFilter.medium => 'Medium',
        PriorityFilter.low    => 'Low',
      };
  Color color(BuildContext ctx) => switch (this) {
        PriorityFilter.high   => Constants.prioHigh,
        PriorityFilter.medium => Constants.prioMedium,
        PriorityFilter.low    => Constants.prioLow,
        PriorityFilter.all    => Theme.of(ctx).colorScheme.primary,
      };
  IconData get icon => switch (this) {
        PriorityFilter.high   => Icons.keyboard_arrow_up_rounded,
        PriorityFilter.medium => Icons.remove_rounded,
        PriorityFilter.low    => Icons.keyboard_arrow_down_rounded,
        PriorityFilter.all    => Icons.flag_rounded,
      };
}

extension SortOptionExt on SortOption {
  String get label => switch (this) {
        SortOption.newest   => 'Newest first',
        SortOption.oldest   => 'Oldest first',
        SortOption.dueDate  => 'Due date',
        SortOption.priority => 'Priority',
        SortOption.title    => 'Title A–Z',
      };
  IconData get icon => switch (this) {
        SortOption.newest   => Icons.arrow_downward_rounded,
        SortOption.oldest   => Icons.arrow_upward_rounded,
        SortOption.dueDate  => Icons.calendar_today_rounded,
        SortOption.priority => Icons.flag_rounded,
        SortOption.title    => Icons.sort_by_alpha_rounded,
      };
}

// ── View ──────────────────────────────────────────────────────────────────────

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});
  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  StatusFilter   _statusFilter   = StatusFilter.all;
  PriorityFilter _priorityFilter = PriorityFilter.all;
  SortOption     _sortOption     = SortOption.newest;

  bool   _searchOpen  = false;
  String _searchQuery = '';
  final  _searchCtrl  = TextEditingController();
  final  _searchFocus = FocusNode();

  // ── Multi-select state ────────────────────────────────────────────────────
  bool             _selectionMode = false;
  final Set<String> _selectedIds  = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = context.read<AuthViewModel>().currentUser?.email ?? '';
      context.read<TodoViewModel>().loadTodos(email);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Selection helpers ──────────────────────────────────────────────────────

  void _enterSelectionMode(String firstId) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(firstId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<TodoModel> visible) {
    setState(() {
      if (_selectedIds.length == visible.length) {
        // Already all selected → deselect all & exit
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(visible.map((t) => t.id));
      }
    });
  }

  List<TodoModel> _selectedTodos(List<TodoModel> all) =>
      all.where((t) => _selectedIds.contains(t.id)).toList();

  // ── Bulk actions ───────────────────────────────────────────────────────────

  Future<void> _bulkDelete(List<TodoModel> todos) async {
    final count = todos.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.delete_rounded,
            color: Constants.prioHigh, size: 36),
        title: Text('Delete $count Task${count == 1 ? '' : 's'}?',
            textAlign: TextAlign.center),
        content: Text(
          count == 1
              ? '"${todos.first.title}" will be permanently deleted.'
              : '$count tasks will be permanently deleted.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12)),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Constants.prioHigh,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            icon:  const Icon(Icons.delete_rounded,
                size: 18, color: Colors.white),
            label: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final email  = context.read<AuthViewModel>().currentUser?.email ?? '';
    final todoVm = context.read<TodoViewModel>();
    for (final t in todos) {
      await todoVm.deleteTodo(ownerEmail: email, todoId: t.id);
    }
    _exitSelectionMode();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$count task${count == 1 ? '' : 's'} deleted'),
      backgroundColor: Constants.prioHigh.withOpacity(0.85),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _bulkMarkDone(List<TodoModel> todos) async {
    final allDone = todos.every((t) => t.completed);
    final count   = todos.length;
    final action  = allDone ? 'Mark as Pending' : 'Mark as Done';
    final icon    = allDone
        ? Icons.radio_button_unchecked_rounded
        : Icons.check_circle_outline_rounded;
    final color   = allDone ? Colors.blueGrey : Constants.prioLow;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        icon: Icon(icon, color: color, size: 36),
        title: Text('$action?', textAlign: TextAlign.center),
        content: Text(
          count == 1
              ? '"${todos.first.title}" will be marked as ${allDone ? 'pending' : 'done'}.'
              : '$count tasks will be marked as ${allDone ? 'pending' : 'done'}.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12)),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            icon:  Icon(icon, size: 18, color: Colors.white),
            label: Text(allDone ? 'Mark Pending' : 'Mark Done',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final email  = context.read<AuthViewModel>().currentUser?.email ?? '';
    final todoVm = context.read<TodoViewModel>();
    for (final t in todos) {
      if (t.completed == allDone) {
        await todoVm.toggleCompleted(ownerEmail: email, todo: t);
      }
    }
    _exitSelectionMode();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(allDone
          ? '$count task${count == 1 ? '' : 's'} marked pending'
          : '$count task${count == 1 ? '' : 's'} marked done'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _bulkPin(List<TodoModel> todos) async {
    final allPinned = todos.every((t) => t.pinned);
    final count     = todos.length;
    final action    = allPinned ? 'Unpin' : 'Pin to Top';
    final icon      = allPinned
        ? Icons.push_pin_outlined
        : Icons.push_pin_rounded;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          icon: Icon(icon, color: cs.primary, size: 36),
          title: Text('$action?', textAlign: TextAlign.center),
          content: Text(
            count == 1
                ? '"${todos.first.title}" will be ${allPinned ? 'unpinned' : 'pinned to the top'}.'
                : '$count tasks will be ${allPinned ? 'unpinned' : 'pinned to the top'}.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12)),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
              icon:  Icon(icon, size: 18,
                  color: cs.onPrimary),
              label: Text(action,
                  style: TextStyle(color: cs.onPrimary)),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    final email  = context.read<AuthViewModel>().currentUser?.email ?? '';
    final todoVm = context.read<TodoViewModel>();
    for (final t in todos) {
      if (t.pinned == allPinned) {
        await todoVm.togglePin(ownerEmail: email, todo: t);
      }
    }
    _exitSelectionMode();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(allPinned
          ? '$count task${count == 1 ? '' : 's'} unpinned'
          : '$count task${count == 1 ? '' : 's'} pinned to top'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // Edit is only available when exactly 1 is selected
  void _editSingle(TodoModel todo) {
    _exitSelectionMode();
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => TodoFormSheet(existing: todo),
    );
  }

  // ── Single-task actions (normal mode) ─────────────────────────────────────

  void _openAddSheet() => showModalBottomSheet(
        context:            context,
        isScrollControlled: true,
        backgroundColor:    Colors.transparent,
        builder: (_) => const TodoFormSheet(),
      );

  void _openEditSheet(TodoModel todo) => showModalBottomSheet(
        context:            context,
        isScrollControlled: true,
        backgroundColor:    Colors.transparent,
        builder: (_) => TodoFormSheet(existing: todo),
      );

  Future<void> _deleteSingle(TodoModel todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.delete_rounded,
            color: Constants.prioHigh, size: 36),
        title: const Text('Delete Task?', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('"${todo.title}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('This task will be permanently deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12)),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Constants.prioHigh,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            icon:  const Icon(Icons.delete_rounded,
                size: 18, color: Colors.white),
            label: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final email = context.read<AuthViewModel>().currentUser?.email ?? '';
    await context.read<TodoViewModel>()
        .deleteTodo(ownerEmail: email, todoId: todo.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('"${todo.title}" deleted',
            overflow: TextOverflow.ellipsis)),
      ]),
      behavior:        SnackBarBehavior.floating,
      backgroundColor: Constants.prioHigh.withOpacity(0.85),
    ));
  }

  Future<void> _togglePin(TodoModel todo) async {
    final email = context.read<AuthViewModel>().currentUser?.email ?? '';
    await context.read<TodoViewModel>()
        .togglePin(ownerEmail: email, todo: todo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(todo.pinned ? 'Task unpinned' : 'Task pinned to top'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.delete_sweep_rounded,
            color: Constants.prioHigh, size: 36),
        title: const Text('Delete All Todos?',
            textAlign: TextAlign.center),
        content: Text(
          'All ${context.read<TodoViewModel>().totalCount} tasks will be permanently deleted.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.grey.shade600, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12)),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Constants.prioHigh,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            icon:  const Icon(Icons.delete_sweep_rounded,
                size: 18, color: Colors.white),
            label: const Text('Delete All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final email = context.read<AuthViewModel>().currentUser?.email ?? '';
    await context.read<TodoViewModel>().deleteAllTodos(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All todos deleted.')),
    );
  }

  // ── Filter + sort ──────────────────────────────────────────────────────────

  List<TodoModel> _applyFilters(List<TodoModel> all) {
    final now  = DateTime.now();
    var   list = all.where((t) {
      final passStatus = switch (_statusFilter) {
        StatusFilter.all       => true,
        StatusFilter.pending   => !t.completed,
        StatusFilter.completed => t.completed,
        StatusFilter.overdue   =>
            !t.completed && t.dueDate != null && t.dueDate!.isBefore(now),
      };
      final passPriority = switch (_priorityFilter) {
        PriorityFilter.all    => true,
        PriorityFilter.high   => t.priority == 'High',
        PriorityFilter.medium => t.priority == 'Medium',
        PriorityFilter.low    => t.priority == 'Low',
      };
      final q          = _searchQuery.toLowerCase().trim();
      final passSearch = q.isEmpty || t.title.toLowerCase().contains(q);
      return passStatus && passPriority && passSearch;
    }).toList();

    list.sort((a, b) => switch (_sortOption) {
          SortOption.newest   => b.createdAt.compareTo(a.createdAt),
          SortOption.oldest   => a.createdAt.compareTo(b.createdAt),
          SortOption.title    =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          SortOption.dueDate  => () {
              if (a.dueDate == null && b.dueDate == null) return 0;
              if (a.dueDate == null) return 1;
              if (b.dueDate == null) return -1;
              return a.dueDate!.compareTo(b.dueDate!);
            }(),
          SortOption.priority => () {
              const o = {'High': 0, 'Medium': 1, 'Low': 2};
              return (o[a.priority] ?? 1).compareTo(o[b.priority] ?? 1);
            }(),
        });
    return list;
  }

  bool get _hasActiveFilters =>
      _statusFilter   != StatusFilter.all   ||
      _priorityFilter != PriorityFilter.all ||
      _sortOption     != SortOption.newest;

  void _clearAllFilters() => setState(() {
        _statusFilter   = StatusFilter.all;
        _priorityFilter = PriorityFilter.all;
        _sortOption     = SortOption.newest;
      });

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) { _searchCtrl.clear(); _searchQuery = ''; }
    });
    if (_searchOpen) Future.delayed(150.ms, () => _searchFocus.requestFocus());
  }

  void _showSortSheet() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 16),
          const Text('Sort By',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...SortOption.values.map((opt) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(opt.icon,
                    color: _sortOption == opt ? cs.primary : null),
                title: Text(opt.label,
                    style: TextStyle(
                      fontWeight: _sortOption == opt ? FontWeight.w700 : null,
                      color:      _sortOption == opt ? cs.primary : null,
                    )),
                trailing: _sortOption == opt
                    ? Icon(Icons.check_rounded, color: cs.primary) : null,
                onTap: () {
                  setState(() => _sortOption = opt);
                  Navigator.pop(context);
                },
              )),
        ]),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthViewModel>();
    final todoVm = context.watch<TodoViewModel>();
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user  = auth.currentUser;
    final email = user?.email ?? '';
    final name  = user?.displayName ?? email.split('@').first;

    final all    = todoVm.todos;
    final shown  = _applyFilters(all);
    final active = _hasActiveFilters;

    final pinnedItems   = shown.where((t) => t.pinned).toList();
    final unpinnedItems = shown.where((t) => !t.pinned).toList();
    final hasPinned     = pinnedItems.isNotEmpty;

    final selectedTodos = _selectedTodos(all);
    final selCount      = _selectedIds.length;
    final allSelected   = selCount == shown.length && shown.isNotEmpty;
    final allDone       = selectedTodos.every((t) => t.completed);
    final allPinned     = selectedTodos.every((t) => t.pinned);

    return PopScope(
      // Back button exits selection mode first
      canPop: !_selectionMode,
      onPopInvoked: (didPop) {
        if (!didPop && _selectionMode) _exitSelectionMode();
      },
      child: Scaffold(
        appBar: _selectionMode
            ? _buildSelectionAppBar(
                cs, isDark, selCount, shown, allSelected)
            : _buildNormalAppBar(cs, isDark, all, name),

        // ── Multi-select action bar ─────────────────────────────────────────
        bottomNavigationBar: _selectionMode
            ? _buildActionBar(cs, isDark, selectedTodos, allDone, allPinned)
            : null,

        body: RefreshIndicator(
          onRefresh: () async => todoVm.loadTodos(email),
          child: CustomScrollView(
            slivers: [
              // Filter pills (hidden in selection mode)
              if (!_selectionMode)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          ...StatusFilter.values.map((f) => _Pill(
                                label:    f.label,
                                selected: _statusFilter == f,
                                color:    cs.primary,
                                onTap: () =>
                                    setState(() => _statusFilter = f),
                              )),
                          Container(
                            width: 1, height: 22,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          ...PriorityFilter.values.skip(1).map((p) {
                            final sel = _priorityFilter == p;
                            return _PriorityPill(
                              label:    p.label,
                              icon:     p.icon,
                              selected: sel,
                              color:    p.color(context),
                              onTap: () => setState(() =>
                                  _priorityFilter =
                                      sel ? PriorityFilter.all : p),
                            );
                          }),
                          if (active) ...[
                            const SizedBox(width: 4),
                            _ClearPill(onTap: _clearAllFilters),
                          ],
                        ]),
                      ),
                      if (_searchQuery.isNotEmpty ||
                          _sortOption != SortOption.newest)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                          child: Row(children: [
                            if (_searchQuery.isNotEmpty)
                              Text(
                                '${shown.length} result${shown.length == 1 ? '' : 's'} for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            if (_searchQuery.isNotEmpty &&
                                _sortOption != SortOption.newest)
                              Text(' · ',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white38 : Colors.black38)),
                            if (_sortOption != SortOption.newest)
                              Row(children: [
                                Icon(_sortOption.icon,
                                    size: 12, color: cs.primary),
                                const SizedBox(width: 3),
                                Text(_sortOption.label,
                                    style: TextStyle(
                                        fontSize: 12, color: cs.primary)),
                              ]),
                          ]),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                ),

              // Empty state
              if (shown.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.checklist_rounded,
                        size:  72,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No results for "$_searchQuery"'
                            : all.isEmpty
                                ? 'No todos yet'
                                : 'No matching todos',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_searchQuery.isNotEmpty || active)
                        TextButton.icon(
                          onPressed: () {
                            _clearAllFilters();
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon:  const Icon(Icons.refresh_rounded),
                          label: const Text('Clear filters'),
                        )
                      else if (all.isEmpty)
                        Text('Tap + to add your first encrypted todo',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white24 : Colors.black26,
                            )),
                    ]).animate().fadeIn(duration: 400.ms),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.only(
                      bottom: _selectionMode ? 20 : 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Pinned section
                      if (hasPinned) ...[
                        _SectionHeader(
                          icon:  Icons.push_pin_rounded,
                          label: 'Pinned',
                          color: cs.primary,
                        ),
                        ...pinnedItems.asMap().entries.map((e) =>
                            _buildCard(e.value, e.key, email, todoVm)),
                        const SizedBox(height: 4),
                        Divider(
                          height: 1, indent: 16, endIndent: 16,
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Other tasks
                      if (unpinnedItems.isNotEmpty) ...[
                        if (hasPinned)
                          _SectionHeader(
                            icon:  Icons.list_rounded,
                            label: 'Tasks',
                            color: isDark
                                ? Colors.white38 : Colors.black38,
                          ),
                        ...unpinnedItems.asMap().entries.map((e) =>
                            _buildCard(
                              e.value,
                              hasPinned
                                  ? pinnedItems.length + e.key
                                  : e.key,
                              email,
                              todoVm,
                            )),
                      ],
                    ]),
                  ),
                ),
            ],
          ),
        ),

        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: _openAddSheet,
                icon:      const Icon(Icons.add_rounded),
                label:     const Text('Add Todo'),
              ).animate().scale(
                  delay: 300.ms, duration: 400.ms,
                  curve: Curves.elasticOut),
      ),
    );
  }

  // ── Normal AppBar ──────────────────────────────────────────────────────────
  PreferredSizeWidget _buildNormalAppBar(
      ColorScheme cs, bool isDark, List<TodoModel> all, String name) {
    return AppBar(
      title: _searchOpen
          ? TextField(
              controller: _searchCtrl,
              focusNode:  _searchFocus,
              onChanged:  (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText:  'Search todos...',
                border:    InputBorder.none,
                hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38),
              ),
            )
          : Column(children: [
              const Text('CipherTask',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              Text(name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  )),
            ]),
      actions: [
        IconButton(
          icon: Icon(_searchOpen
              ? Icons.search_off_rounded : Icons.search_rounded),
          tooltip:   _searchOpen ? 'Close search' : 'Search',
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: Icon(Icons.sort_rounded,
              color: _sortOption != SortOption.newest ? cs.primary : null),
          tooltip:   'Sort',
          onPressed: _showSortSheet,
        ),
        IconButton(
          icon:      const Icon(Icons.person_rounded),
          tooltip:   'Profile',
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileView())),
        ),
        if (all.isNotEmpty)
          IconButton(
            icon:      const Icon(Icons.delete_sweep_outlined),
            tooltip:   'Delete all',
            onPressed: _deleteAll,
          ),
      ],
    );
  }

  // ── Selection AppBar ───────────────────────────────────────────────────────
  PreferredSizeWidget _buildSelectionAppBar(
      ColorScheme cs, bool isDark, int selCount,
      List<TodoModel> shown, bool allSelected) {
    return AppBar(
      leading: IconButton(
        icon:      const Icon(Icons.close_rounded),
        tooltip:   'Cancel selection',
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        selCount == 0 ? 'Select tasks' : '$selCount selected',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        // Select All / Deselect All
        TextButton.icon(
          onPressed: () => _selectAll(shown),
          icon:  Icon(
            allSelected
                ? Icons.deselect_rounded
                : Icons.select_all_rounded,
            size: 20,
          ),
          label: Text(allSelected ? 'None' : 'All',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ── Multi-select action bottom bar ─────────────────────────────────────────
  Widget _buildActionBar(ColorScheme cs, bool isDark,
      List<TodoModel> selected, bool allDone, bool allPinned) {
    final count = selected.length;
    final canEdit = count == 1;

    return SafeArea(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset:     const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pin / Unpin
            _ActionBarBtn(
              icon:    allPinned
                  ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              label:   allPinned ? 'Unpin' : 'Pin',
              color:   cs.primary,
              enabled: count > 0,
              onTap:   () => _bulkPin(selected),
            ),

            // Mark done / pending
            _ActionBarBtn(
              icon:    allDone
                  ? Icons.radio_button_unchecked_rounded
                  : Icons.check_circle_outline_rounded,
              label:   allDone ? 'Pending' : 'Done',
              color:   Constants.prioLow,
              enabled: count > 0,
              onTap:   () => _bulkMarkDone(selected),
            ),

            // Edit (only when 1 selected)
            _ActionBarBtn(
              icon:    Icons.edit_rounded,
              label:   'Edit',
              color:   cs.secondary,
              enabled: canEdit,
              onTap:   canEdit ? () => _editSingle(selected.first) : null,
            ),

            // Delete
            _ActionBarBtn(
              icon:    Icons.delete_rounded,
              label:   'Delete',
              color:   Constants.prioHigh,
              enabled: count > 0,
              onTap:   () => _bulkDelete(selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      TodoModel todo, int index, String email, TodoViewModel todoVm) {
    return TodoCard(
      key:           ValueKey(todo.id),
      todo:          todo,
      decryptedNote: todoVm.decryptNoteForUi(todo),
      isOverdue:     todoVm.isOverdue(todo),
      index:         index,
      selectionMode: _selectionMode,
      isSelected:    _selectedIds.contains(todo.id),
      onLongPress:   () => _enterSelectionMode(todo.id),
      onTapInSelect: () => _toggleSelect(todo.id),
      onToggle: () =>
          todoVm.toggleCompleted(ownerEmail: email, todo: todo),
      onEdit:   () => _openEditSheet(todo),
      onDelete: () => _deleteSingle(todo),
      onPin:    () => _togglePin(todo),
    );
  }
}

// ── Action bar button ─────────────────────────────────────────────────────────

class _ActionBarBtn extends StatelessWidget {
  final IconData      icon;
  final String        label;
  final Color         color;
  final bool          enabled;
  final VoidCallback? onTap;
  const _ActionBarBtn({
    required this.icon,  required this.label,
    required this.color, required this.enabled,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : color.withOpacity(0.3);
    return Expanded(
      child: InkWell(
        onTap:        enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 26, color: effectiveColor),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                  color:      effectiveColor,
                )),
          ]),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
        child: Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label.toUpperCase(),
              style: TextStyle(
                fontSize:      11,
                fontWeight:    FontWeight.w700,
                letterSpacing: 1.1,
                color:         color,
              )),
        ]),
      );
}

// ── Filter pills ──────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label; final bool selected;
  final Color color;  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            )),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String label; final IconData icon;
  final bool selected; final Color color; final VoidCallback onTap;
  const _PriorityPill({required this.label, required this.icon,
      required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13,
                color: selected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                )),
          ]),
        ),
      );
}

class _ClearPill extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearPill({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Constants.prioHigh.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Constants.prioHigh.withOpacity(0.4)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.close_rounded, size: 13, color: Constants.prioHigh),
            SizedBox(width: 4),
            Text('Clear',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      Constants.prioHigh,
                )),
          ]),
        ),
      );
}