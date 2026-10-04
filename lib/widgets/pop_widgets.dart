import 'package:flutter/material.dart';
import 'package:vibe_check/screen/app_theme.dart';

BoxDecoration popDecoration(
  Color color, {
  double radius = 20,
  double shadow = 4,
  bool pill = false,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(pill ? 999 : radius),
    border: Border.all(color: AppColors.ink, width: 2),
    boxShadow: shadow == 0
        ? null
        : [BoxShadow(color: AppColors.ink, offset: Offset(shadow, shadow))],
  );
}

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day}/${t.month}';
}

SnackBar popSnack(String message) => SnackBar(content: Text(message));

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(popSnack(message));
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.ink, width: 2),
      ),
      title: Text(
        'Delete this $what?',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: const Text('It disappears for everyone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            'Keep it',
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Delete',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Outlined card with a hard offset shadow.
class PopCard extends StatelessWidget {
  const PopCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: popDecoration(color),
      child: child,
    );
  }
}

/// Pill used for filters, tags and picker options.
class PopChip extends StatelessWidget {
  const PopChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: popDecoration(
          selected ? color : Colors.white,
          pill: true,
          shadow: selected ? 3 : 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ),
    );
  }
}

/// Small tilted label.
class Sticker extends StatelessWidget {
  const Sticker({
    super.key,
    required this.label,
    this.color = Colors.white,
    this.angle = 0.05,
  });
  final String label;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: popDecoration(color, pill: true, shadow: 2),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        ),
      ),
    );
  }
}

/// Button that physically presses into its shadow.
class PopButton extends StatefulWidget {
  const PopButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.tangerine,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool loading;

  @override
  State<PopButton> createState() => _PopButtonState();
}

class _PopButtonState extends State<PopButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final pressed = _down && enabled;
    final shadow = pressed ? 0.0 : 4.0;

    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(4 - shadow, 4 - shadow, 0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          width: double.infinity,
          decoration: popDecoration(
            enabled || widget.loading ? widget.color : AppColors.disabled,
            radius: 16,
            shadow: shadow,
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.ink,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.hint,
  });
  final String emoji;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(hint, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📡', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: PopButton(
                label: 'Retry',
                color: AppColors.butter,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
