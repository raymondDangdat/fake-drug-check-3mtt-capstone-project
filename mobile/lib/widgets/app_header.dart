import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'responsive_layout.dart';

/// Top bar navigation header for Web & Desktop with brand logo and route links.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final int activeIndex;
  final ValueChanged<int>? onIndexSelected;
  final Widget? trailing;

  const AppHeader({
    super.key,
    this.activeIndex = 0,
    this.onIndexSelected,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Container(
      height: 64.0,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: MaxWidthContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Brand Logo & Title
            Flexible(
              child: InkWell(
                onTap: () {
                  if (onIndexSelected != null) {
                    onIndexSelected!(0);
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
                  }
                },
                borderRadius: AppRadius.md,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.md,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'FakeDrugChecker',
                                    style: AppTypography.title.copyWith(fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: AppRadius.sm,
                                  ),
                                  child: Text(
                                    'NG',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Authenticity Portal',
                              style: AppTypography.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Desktop Navigation Links
            if (isDesktop && onIndexSelected != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderNavLink(
                    label: 'Verify Medicine',
                    icon: Icons.search_rounded,
                    isActive: activeIndex == 0,
                    onTap: () => onIndexSelected!(0),
                  ),
                  const SizedBox(width: 4),
                  _HeaderNavLink(
                    label: 'Verification History',
                    icon: Icons.history_rounded,
                    isActive: activeIndex == 1,
                    onTap: () => onIndexSelected!(1),
                  ),
                  const SizedBox(width: 4),
                  _HeaderNavLink(
                    label: 'About & Guide',
                    icon: Icons.info_outline_rounded,
                    isActive: activeIndex == 2,
                    onTap: () => onIndexSelected!(2),
                  ),
                ],
              ),
            ],

            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _HeaderNavLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _HeaderNavLink({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppColors.primarySurface : Colors.transparent,
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
