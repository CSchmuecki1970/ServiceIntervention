import 'package:flutter/material.dart';

class NavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  NavItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class SidebarNavigation extends StatefulWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final bool isExpanded;

  const SidebarNavigation({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.isExpanded = true,
  });

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  late bool isExpanded;
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isExpanded;
    selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 250 : 70,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[100],
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300] ?? Colors.grey,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.construction,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Plan',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Manager',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 8 : 4,
                    vertical: 4,
                  ),
                  child: Tooltip(
                    message: item.label,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                          item.onTap();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white70
                                        : Colors.grey[600],
                                size: 24,
                              ),
                              if (isExpanded) ...[
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                            : Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Toggle Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
