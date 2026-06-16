import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ProTagSize { normal, small }

class ProTag extends StatelessWidget {
  final ProTagSize size;

  const ProTag({super.key, this.size = ProTagSize.normal});

  @override
  Widget build(BuildContext context) {
    final double height = size == ProTagSize.normal ? 25 : 18;
    final double iconSize = size == ProTagSize.normal ? 14 : 12;
    final double verticalPadding = size == ProTagSize.normal ? 4 : 2;
    const Color goldDark = Color(0xff6b5413);

    return Container(
      constraints: BoxConstraints(maxHeight: height),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xfff7e8c8), Color(0xffeed598)],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: verticalPadding),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium, size: iconSize, color: goldDark),
            const SizedBox(width: 3),
            Text(
              'PRO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: size == ProTagSize.normal ? 10 : 9,
                fontWeight: FontWeight.w700,
                color: goldDark,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
