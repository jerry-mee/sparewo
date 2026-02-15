import 'package:flutter/material.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/desktop_layout.dart';

class DesktopSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsets? padding;

  const DesktopSection({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(vertical: DesktopWebScale.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.desktopH1.copyWith(
                fontSize: 46,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.05,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: 17,
                  height: 1.45,
                  color: theme.hintColor,
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
          child,
        ],
      ),
    );
  }
}
