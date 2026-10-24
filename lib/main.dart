import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'features/demo/demo_shell.dart';

void main() {
  runApp(const SparkNestDemo());
}

class SparkNestDemo extends StatelessWidget {
  const SparkNestDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SparkNest · Condo cleaning booking demo',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const DemoShell(),
    );
  }
}
