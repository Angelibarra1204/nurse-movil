import 'package:flutter/material.dart';

class NavTabs extends StatelessWidget {
  final int currentIndex;
  final List<String> titles;
  final ValueChanged<int> onTabSelected;

  const NavTabs({
    Key? key,
    required this.currentIndex,
    required this.titles,
    required this.onTabSelected,
  }) : super(key: key);

    String getIcon(int index) {
    switch (index) {
      case 0:
        return "📊";
      case 1:
        return "👥";
      case 2:
        return "📄";
      case 3:
        return "🗓️";
      default:
        return "📁";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2F855A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(titles.length, (index) {
          final active = currentIndex == index;
          return SizedBox(
            width: 160,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF2F855A), Color(0xFF276749)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF48BB78), Color(0xFF38A169)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? const Color(0x662F855A)
                        : const Color(0x6648BB78),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => onTabSelected(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      getIcon(index),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titles[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}