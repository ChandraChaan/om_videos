import 'package:flutter/material.dart';

class MobileFrame extends StatelessWidget {
  final Widget child;
  final double mobileWidth;

  const MobileFrame({
    super.key,
    required this.child,
    this.mobileWidth = 390, // iPhone 14 Pro width
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > mobileWidth) {
          return Container(
            color: Colors.grey.shade200, // Background outside frame
            child: Center(
              child: SizedBox(
                width: mobileWidth,
                child: child,
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}