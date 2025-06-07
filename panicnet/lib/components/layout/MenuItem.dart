import 'package:flutter/material.dart';

class MenuItem extends StatelessWidget {
  final Widget child;
  const MenuItem({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
      child: child,
    );
  }
}
