import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/enums/pao_tone.dart';

export '../../domain/enums/pao_tone.dart';

class PaoMeter extends StatelessWidget {
  final double value;
  final PaoTone tone;
  final double height;

  const PaoMeter({
    super.key,
    required this.value,
    required this.tone,
    this.height = 6.0,
  });

  Color get _toneColor {
    switch (tone) {
      case PaoTone.ok:
        return const Color(0xffe58b73);
      case PaoTone.warn:
        return const Color(0xffd9a648);
      case PaoTone.bad:
        return const Color(0xffba1a1a);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.surfaceHighest),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(color: _toneColor),
            ),
          ],
        ),
      ),
    );
  }
}
