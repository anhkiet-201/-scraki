import 'package:flutter/material.dart';

class TemplateSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<String> templateNames;

  const TemplateSelector({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.templateNames,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: templateNames.length,
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;
        return GestureDetector(
          onTap: () => onSelect(index),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Text(
              templateNames[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
