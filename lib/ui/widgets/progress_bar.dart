import 'package:flutter/material.dart';

class ThinProgressBar extends StatelessWidget {
  final int total;
  final int learned;
  final int inProgress;

  const ThinProgressBar({
    super.key,
    required this.total,
    required this.learned,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        height: 4,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    final learnedFlex = (learned / total * 1000).toInt();
    final inProgressFlex = (inProgress / total * 1000).toInt();
    final notStartedFlex = 1000 - learnedFlex - inProgressFlex;

    return Container(
      height: 4,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (learnedFlex > 0)
            Expanded(flex: learnedFlex, child: Container(color: Colors.green)),
          if (inProgressFlex > 0)
            Expanded(flex: inProgressFlex, child: Container(color: Colors.yellow)),
          if (notStartedFlex > 0)
            Expanded(flex: notStartedFlex, child: Container(color: Colors.grey[800])),
        ],
      ),
    );
  }
}
