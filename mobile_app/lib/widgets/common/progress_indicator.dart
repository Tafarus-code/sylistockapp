import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomProgressIndicator extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const CustomProgressIndicator({
    Key? key,
    required this.value,
    required this.color,
    this.height = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.dividerColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
