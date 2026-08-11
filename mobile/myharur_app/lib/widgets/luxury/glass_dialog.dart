import 'package:flutter/material.dart';
import '../../theme/luxury_theme.dart';
import 'glass_surface.dart';
import 'glass_button.dart';

class GlassDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const GlassDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    String? cancelText,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.70),
      builder: (context) => GlassDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: GlassSurface(
        level: GlassLevel.level3,
        borderRadius: LuxuryShapes.dialogRadius,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: LuxuryTypography.sectionTitle),
            const SizedBox(height: 12),
            Text(
              content,
              style: LuxuryTypography.body.copyWith(
                color: LuxuryColors.secondaryText,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: GlassButton(
                      text: cancelText!,
                      variant: GlassButtonVariant.outlineGlass,
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onCancel != null) onCancel!();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: GlassButton(
                    text: confirmText,
                    variant: GlassButtonVariant.primaryRed,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GlassBottomSheet extends StatelessWidget {
  final Widget child;

  const GlassBottomSheet({super.key, required this.child});

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassBottomSheet(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.level3,
      borderRadius: LuxuryShapes.sheetRadius,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
