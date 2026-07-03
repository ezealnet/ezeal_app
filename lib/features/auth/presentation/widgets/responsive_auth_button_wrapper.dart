import 'package:flutter/material.dart';

class ResponsiveAuthButtonWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveAuthButtonWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    if (isMobile) {
      return SizedBox(
        width: double.infinity,
        child: child,
      );
    } else {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: SizedBox(
            width: double.infinity,
            child: child,
          ),
        ),
      );
    }
  }
}
