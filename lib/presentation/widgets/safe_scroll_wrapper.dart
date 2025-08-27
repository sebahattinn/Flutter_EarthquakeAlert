import 'package:flutter/material.dart';

class SafeScrollWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const SafeScrollWrapper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).padding;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                // Alt navigasyon / gesture bar için ekstra taban boşluğu
                padding: padding.copyWith(
                  bottom: padding.bottom + insets.bottom + 8,
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
