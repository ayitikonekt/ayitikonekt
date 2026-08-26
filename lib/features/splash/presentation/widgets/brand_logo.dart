import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showName;

  const BrandLogo({super.key, this.size = 82, this.showName = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * .24),
          child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ColoredBox(color: Color(0xFF0646D8))),
                  Expanded(child: ColoredBox(color: Color(0xFFF20D1B))),
                ],
              ),
              Icon(
                Icons.handshake_rounded,
                color: Colors.white,
                size: size * .58,
              ),
            ],
          ),
          ),
        ),
        if (showName) ...[
          SizedBox(height: size * .18),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: size * .38,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
              children: const [
                TextSpan(text: 'Ayiti', style: TextStyle(color: Color(0xFF0646D8))),
                TextSpan(text: 'Konekt', style: TextStyle(color: Color(0xFFF20D1B))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
