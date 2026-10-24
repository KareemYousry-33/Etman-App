import 'package:flutter/material.dart';

class CustomEtmanNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomEtmanNavBar({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Labels matching the user's screenshot
    final List<Map<String, dynamic>> items = [
      {'label': 'الرئيسية', 'icon': Icons.home_rounded},
      {'label': 'طبيبك الذكي', 'icon': Icons.smart_toy_rounded},
      {'label': 'معاملاتي', 'icon': Icons.calendar_month_rounded},
      {'label': 'حسابي', 'icon': Icons.person_rounded},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25), // Floating capsule
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E5D57), // Dark Teal from screenshot
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            // Note: Since it's RTL in screenshot, we'll keep the list ordered 
            // and Row will naturally lay them out RTL if Directionality is set.
            return _buildNavItem(index, items[index]['icon'], items[index]['label']);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26A69A) : Colors.transparent, // Highlight pill
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              icon,
              color: Colors.white, // All icons white in screenshot
              size: 26,
            ),
            if (!isSelected) ...[
              const SizedBox(height: 4),
              // We could add a label below icon here if it wasn't selected 
              // but the screenshot shows labels for ALL items below icons.
              // Wait, let's look closer at the screenshot.
            ],
          ],
        ),
      ),
    );
  }
}
