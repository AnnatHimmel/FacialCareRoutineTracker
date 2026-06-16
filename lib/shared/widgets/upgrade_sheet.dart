import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

Future<void> showUpgradeSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpgradeSheet(),
    );

class UpgradeSheet extends StatefulWidget {
  const UpgradeSheet({super.key});

  @override
  State<UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<UpgradeSheet> {
  bool _isYearly = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        28 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Overline
          Text(
            'GLOW PRO',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.22 * 16,
              color: const Color(0xff8f6a15),
            ),
          ),
          const SizedBox(height: 4),

          // Headline
          Text(
            'שדרגי את השגרה שלך',
            style: AppTypography.headlineLg.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),

          // Sub-headline
          Text(
            'כלים מתקדמים לתוצאות אמיתיות',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Feature rows
          const _FeatureRow(
            icon: Icons.auto_stories_rounded,
            title: 'תיעוד התקדמות',
            sub: 'השווי לפני ואחרי',
          ),
          const SizedBox(height: 8),
          const _FeatureRow(
            icon: Icons.spa_rounded,
            title: 'ניהול המדף',
            sub: 'כל המוצרים במקום אחד',
          ),
          const SizedBox(height: 8),
          const _FeatureRow(
            icon: Icons.schedule_rounded,
            title: 'תוקף ו-PAO',
            sub: 'תדעי מתי לזרוק',
          ),
          const SizedBox(height: 20),

          // Pricing toggle
          _PricingToggle(
            isYearly: _isYearly,
            onChanged: (v) => setState(() => _isYearly = v),
          ),
          const SizedBox(height: 16),

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffb3892a), Color(0xff8f6a15)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40b3892a),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'התחילי עם PRO',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dismiss link
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'אולי אחר כך',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xfffff8e7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xff8f6a15)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PricingToggle extends StatelessWidget {
  final bool isYearly;
  final ValueChanged<bool> onChanged;

  const _PricingToggle({
    required this.isYearly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _PricingOption(
            label: 'שנתי',
            price: '8.25 ₪ לחודש',
            active: isYearly,
            badge: 'חיסכון 30%',
            onTap: () => onChanged(true),
          ),
          _PricingOption(
            label: 'חודשי',
            price: '11.90 ₪ לחודש',
            active: !isYearly,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _PricingOption extends StatelessWidget {
  final String label;
  final String price;
  final bool active;
  final String? badge;
  final VoidCallback onTap;

  const _PricingOption({
    required this.label,
    required this.price,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? AppColors.glowSm : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                price,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xfff7e8c8), Color(0xffeed598)],
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff6b5413),
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
