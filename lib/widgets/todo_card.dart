import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/todo_model.dart';
import '../utils/constants.dart';

class TodoCard extends StatelessWidget {
  final TodoModel    todo;
  final String       decryptedNote;
  final bool         isOverdue;
  final int          index;

  // Normal mode callbacks
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  // Selection mode
  final bool         selectionMode;
  final bool         isSelected;
  final VoidCallback onLongPress;   // enters selection mode
  final VoidCallback onTapInSelect; // tap to select/deselect in selection mode

  const TodoCard({
    super.key,
    required this.todo,
    required this.decryptedNote,
    required this.isOverdue,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    required this.selectionMode,
    required this.isSelected,
    required this.onLongPress,
    required this.onTapInSelect,
  });

  Color    _priorityColor() => todo.priority == 'High'
      ? Constants.prioHigh
      : todo.priority == 'Medium' ? Constants.prioMedium : Constants.prioLow;

  IconData _priorityIcon() => todo.priority == 'High'
      ? Icons.keyboard_arrow_up_rounded
      : todo.priority == 'Medium'
          ? Icons.remove_rounded
          : Icons.keyboard_arrow_down_rounded;

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pColor = _priorityColor();

    // Card border color logic
    final borderColor = isSelected
        ? cs.primary
        : todo.pinned
            ? cs.primary.withOpacity(0.5)
            : isOverdue
                ? Constants.prioHigh.withOpacity(0.35)
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.07));

    final borderWidth = isSelected ? 2.0 : todo.pinned ? 1.8 : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withOpacity(isDark ? 0.12 : 0.08)
              : (isDark ? Constants.dsSurface : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelected
              ? [BoxShadow(
                  color:      cs.primary.withOpacity(0.18),
                  blurRadius: 10, offset: const Offset(0, 2))]
              : todo.pinned
                  ? [BoxShadow(
                      color:      cs.primary.withOpacity(isDark ? 0.18 : 0.10),
                      blurRadius: 12, offset: const Offset(0, 3))]
                  : [BoxShadow(
                      color:      Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                      blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Material(
          color:        Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap:        selectionMode ? onTapInSelect : onEdit,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              onLongPress();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Left: checkbox (normal) OR select circle (selection mode)
                  SizedBox(
                    width: 48,
                    child: selectionMode
                        ? Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: isSelected
                                  ? CircleAvatar(
                                      key:    const ValueKey('sel'),
                                      radius: 13,
                                      backgroundColor: cs.primary,
                                      child: const Icon(
                                          Icons.check_rounded,
                                          size:  16,
                                          color: Colors.white),
                                    )
                                  : CircleAvatar(
                                      key:    const ValueKey('unsel'),
                                      radius: 13,
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        width: 26, height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black26,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          )
                        : Transform.scale(
                            scale: 1.15,
                            child: Checkbox(
                              value:       todo.completed,
                              onChanged:   (_) => onToggle(),
                              activeColor: pColor,
                              checkColor:  Colors.white,
                              shape:       const CircleBorder(),
                              side: BorderSide(
                                color: todo.completed
                                    ? pColor
                                    : (isDark
                                        ? Colors.white38
                                        : Colors.black26),
                                width: 1.8,
                              ),
                            ),
                          ),
                  ),

                  // ── Content ───────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(children: [
                          if (todo.pinned && !selectionMode) ...[
                            Icon(Icons.push_pin_rounded,
                                size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize:   15,
                                fontWeight: FontWeight.w700,
                                decoration: todo.completed
                                    ? TextDecoration.lineThrough : null,
                                color: todo.completed
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),

                        // Note preview
                        if (decryptedNote.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            decryptedNote,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                              decoration: todo.completed
                                  ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Priority + due date
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color:        pColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: pColor.withOpacity(0.4), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_priorityIcon(), size: 13, color: pColor),
                                const SizedBox(width: 3),
                                Text(todo.priority,
                                    style: TextStyle(
                                      fontSize:   12,
                                      fontWeight: FontWeight.w700,
                                      color:      pColor,
                                    )),
                              ],
                            ),
                          ),
                          if (todo.dueDate != null) ...[
                            const SizedBox(width: 8),
                            Row(children: [
                              Icon(Icons.schedule_rounded,
                                  size: 13,
                                  color: isOverdue
                                      ? Constants.prioHigh
                                      : (isDark ? Colors.white38 : Colors.black38)),
                              const SizedBox(width: 3),
                              Text(
                                DateFormat('MMM d').format(todo.dueDate!),
                                style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: FontWeight.w600,
                                  color: isOverdue
                                      ? Constants.prioHigh
                                      : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                            ]),
                          ],
                        ]),
                      ],
                    ),
                  ),

                  // ── Right side: pin + 3-dot (hidden in selection mode) ────
                  if (!selectionMode)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconBtn(
                          icon: todo.pinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          color: todo.pinned
                              ? cs.primary
                              : (isDark ? Colors.white38 : Colors.black38),
                          size:    24,
                          tooltip: todo.pinned ? 'Unpin' : 'Pin to top',
                          onTap:   onPin,
                        ),
                        const SizedBox(height: 4),
                        _IconBtn(
                          icon:    Icons.more_vert_rounded,
                          color:   isDark ? Colors.white54 : Colors.black45,
                          size:    24,
                          tooltip: 'More options',
                          onTap:   _buildMoreSheet(context),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(key: ValueKey('card_${todo.id}'))
        .fadeIn(duration: 250.ms, delay: (index * 40).ms)
        .slideY(begin: 0.08, duration: 250.ms, delay: (index * 40).ms);
  }

  // The ⋮ more sheet (same as long press, for single task)
  VoidCallback _buildMoreSheet(BuildContext context) => () {
        final cs     = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color:        Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      todo.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _SheetAction(
                    icon:  todo.pinned
                        ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                    label: todo.pinned ? 'Unpin Task' : 'Pin to Top',
                    color: cs.primary,
                    onTap: () { Navigator.pop(context); onPin(); },
                  ),
                  _SheetAction(
                    icon:  Icons.edit_rounded,
                    label: 'Edit Task',
                    color: cs.secondary,
                    onTap: () { Navigator.pop(context); onEdit(); },
                  ),
                  _SheetAction(
                    icon: todo.completed
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.check_circle_outline_rounded,
                    label: todo.completed
                        ? 'Mark as Pending' : 'Mark as Complete',
                    color: todo.completed
                        ? Colors.blueGrey : Constants.prioLow,
                    onTap: () { Navigator.pop(context); onToggle(); },
                  ),
                  const Divider(height: 20),
                  _SheetAction(
                    icon:  Icons.delete_rounded,
                    label: 'Delete Task',
                    color: Constants.prioHigh,
                    onTap: () { Navigator.pop(context); onDelete(); },
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      };
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color color;
  final double size;   final String tooltip; final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color,
      required this.size, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: size, color: color),
          ),
        ),
      );
}

class _SheetAction extends StatelessWidget {
  final IconData icon; final String label;
  final Color color;   final VoidCallback onTap;
  const _SheetAction({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color:        color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15,
              color: color == Constants.prioHigh ? color : null,
            )),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 2),
      );
}