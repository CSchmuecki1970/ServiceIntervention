import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/intervention_provider.dart';
import '../providers/theme_provider.dart';
import '../models/service_intervention.dart';
import '../widgets/sidebar_navigation.dart';
import 'intervention_detail_screen.dart';
import 'create_intervention_screen.dart';
import 'settings_screen.dart';
import 'package:intl/intl.dart';

enum DashboardPage {
  home,
  planned,
  inProgress,
  completed,
  settings,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardPage currentPage = DashboardPage.home;

  late List<NavItem> navItems;

  @override
  void initState() {
    super.initState();
    _initializeNavItems();
  }

  void _initializeNavItems() {
    navItems = [
      NavItem(
        label: 'Home',
        icon: Icons.home,
        onTap: () {
          setState(() {
            currentPage = DashboardPage.home;
          });
        },
      ),
      NavItem(
        label: 'Planned',
        icon: Icons.schedule,
        onTap: () {
          setState(() {
            currentPage = DashboardPage.planned;
          });
        },
      ),
      NavItem(
        label: 'In Progress',
        icon: Icons.work_history,
        onTap: () {
          setState(() {
            currentPage = DashboardPage.inProgress;
          });
        },
      ),
      NavItem(
        label: 'Completed',
        icon: Icons.check_circle,
        onTap: () {
          setState(() {
            currentPage = DashboardPage.completed;
          });
        },
      ),
      NavItem(
        label: 'Settings',
        icon: Icons.settings,
        onTap: () {
          setState(() {
            currentPage = DashboardPage.settings;
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on a wide screen (tablet/landscape) or narrow screen (mobile/portrait)
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800; // Tablet breakpoint

    if (isWideScreen) {
      // Wide screen layout with sidebar
      return Scaffold(
        body: Row(
          children: [
            SidebarNavigation(
              items: navItems,
              selectedIndex: currentPage.index,
              isExpanded: false,
            ),
            Expanded(
              child: Column(
                children: [
                  AppBar(
                    title: Text(_getPageTitle(currentPage)),
                    elevation: 1,
                    actions: [
                      if (currentPage != DashboardPage.settings)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Center(
                            child: Consumer<ThemeProvider>(
                              builder: (context, themeProvider, child) {
                                return DropdownButton<AppTheme>(
                                  value: themeProvider.currentTheme,
                                  items: AppTheme.values.map((theme) {
                                    return DropdownMenuItem(
                                      value: theme,
                                      child: Text(_getThemeName(theme)),
                                    );
                                  }).toList(),
                                  onChanged: (theme) {
                                    if (theme != null) {
                                      themeProvider.setTheme(theme);
                                    }
                                  },
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.palette),
                                );
                              },
                            ),
                          ),
                        ),
                      if (currentPage == DashboardPage.home)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreateInterventionScreen(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  Expanded(
                    child: _buildPageContent(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Narrow screen layout with bottom navigation
      return Scaffold(
        appBar: AppBar(
          title: Text(_getPageTitle(currentPage)),
          elevation: 1,
          actions: [
            if (currentPage != DashboardPage.settings)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return DropdownButton<AppTheme>(
                        value: themeProvider.currentTheme,
                        items: AppTheme.values.map((theme) {
                          return DropdownMenuItem(
                            value: theme,
                            child: Text(_getThemeName(theme)),
                          );
                        }).toList(),
                        onChanged: (theme) {
                          if (theme != null) {
                            themeProvider.setTheme(theme);
                          }
                        },
                        underline: const SizedBox(),
                        icon: const Icon(Icons.palette),
                      );
                    },
                  ),
                ),
              ),
            if (currentPage == DashboardPage.home)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CreateInterventionScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
        body: _buildPageContent(context),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentPage.index,
          onTap: (index) {
            setState(() {
              currentPage = DashboardPage.values[index];
            });
          },
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
          type: BottomNavigationBarType.fixed,
        ),
      );
    }
  }

  Widget _buildPageContent(BuildContext context) {
    switch (currentPage) {
      case DashboardPage.home:
        return _buildHomeContent(context);
      case DashboardPage.planned:
        return _buildFilteredContent(context, InterventionStatus.planned);
      case DashboardPage.inProgress:
        return _buildFilteredContent(context, InterventionStatus.inProgress);
      case DashboardPage.completed:
        return _buildFilteredContent(context, InterventionStatus.completed);
      case DashboardPage.settings:
        return const SettingsScreen();
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    return Consumer<InterventionProvider>(
      builder: (context, provider, child) {
        final allInterventions = provider.interventions;
        final planned = provider.filterByStatus(InterventionStatus.planned);
        final inProgress = provider.filterByStatus(InterventionStatus.inProgress);
        final completed = provider.filterByStatus(InterventionStatus.completed);
        final cancelled = provider.filterByStatus(InterventionStatus.cancelled);

        // Get upcoming interventions (next 7 days, sorted by date)
        final upcoming = planned
            .where((i) =>
                i.scheduledDate.isBefore(DateTime.now().add(Duration(days: 7))))
            .toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

        final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

        if (allInterventions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No interventions planned',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first intervention to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CreateInterventionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Intervention'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Stats Grid
              GridView.count(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStatCard(
                    context,
                    label: 'Planned',
                    count: planned.length,
                    color: Colors.blue,
                    icon: Icons.schedule,
                  ),
                  _buildStatCard(
                    context,
                    label: 'In Progress',
                    count: inProgress.length,
                    color: Colors.orange,
                    icon: Icons.work_history,
                  ),
                  _buildStatCard(
                    context,
                    label: 'Completed',
                    count: completed.length,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                  _buildStatCard(
                    context,
                    label: 'Cancelled',
                    count: cancelled.length,
                    color: Colors.grey,
                    icon: Icons.cancel,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Upcoming Section
              if (upcoming.isNotEmpty) ...[
                Text(
                  'Upcoming (Next 7 Days)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final intervention = upcoming[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.calendar_today,
                              color: Colors.blue),
                        ),
                        title: Text(intervention.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(intervention.customer.name),
                            Text(
                              dateFormat.format(intervention.scheduledDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InterventionDetailScreen(
                                interventionId: intervention.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Quick Links
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickActionButton(
                    context,
                    label: 'View Planned',
                    count: planned.length,
                    color: Colors.blue,
                    onTap: () {
                      setState(() {
                        currentPage = DashboardPage.planned;
                      });
                    },
                  ),
                  _buildQuickActionButton(
                    context,
                    label: 'View In Progress',
                    count: inProgress.length,
                    color: Colors.orange,
                    onTap: () {
                      setState(() {
                        currentPage = DashboardPage.inProgress;
                      });
                    },
                  ),
                  _buildQuickActionButton(
                    context,
                    label: 'View Completed',
                    count: completed.length,
                    color: Colors.green,
                    onTap: () {
                      setState(() {
                        currentPage = DashboardPage.completed;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      child: Text('$label ($count)'),
    );
  }

  Widget _buildFilteredContent(
    BuildContext context,
    InterventionStatus status,
  ) {
    return Consumer<InterventionProvider>(
      builder: (context, provider, child) {
        final filteredInterventions = provider.filterByStatus(status);

        if (filteredInterventions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${status.name} interventions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredInterventions.length,
          itemBuilder: (context, index) {
            final intervention = filteredInterventions[index];
            return _InterventionCard(
              intervention: intervention,
              provider: provider,
            );
          },
        );
      },
    );
  }

  String _getPageTitle(DashboardPage page) {
    switch (page) {
      case DashboardPage.home:
        return 'All Interventions';
      case DashboardPage.planned:
        return 'Planned Interventions';
      case DashboardPage.inProgress:
        return 'In Progress';
      case DashboardPage.completed:
        return 'Completed';
      case DashboardPage.settings:
        return 'Settings';
    }
  }

  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.blue:
        return 'Blue';
      case AppTheme.green:
        return 'Green';
      case AppTheme.purple:
        return 'Purple';
      case AppTheme.orange:
        return 'Orange';
      case AppTheme.pink:
        return 'Pink';
      case AppTheme.dracula:
        return 'Dracula';
    }
  }
}

class _InterventionCard extends StatelessWidget {
  final ServiceIntervention intervention;
  final InterventionProvider provider;

  const _InterventionCard({
    required this.intervention,
    required this.provider,
  });

  Color _getStatusColor(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.planned:
        return Colors.blue;
      case InterventionStatus.inProgress:
        return Colors.orange;
      case InterventionStatus.completed:
        return Colors.green;
      case InterventionStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(InterventionStatus status) {
    switch (status) {
      case InterventionStatus.planned:
        return 'Planned';
      case InterventionStatus.inProgress:
        return 'In Progress';
      case InterventionStatus.completed:
        return 'Completed';
      case InterventionStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final statusColor = _getStatusColor(intervention.status);

    final cardWidget = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InterventionDetailScreen(
                interventionId: intervention.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intervention.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      _getStatusText(intervention.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<InterventionStatus>(
                    onSelected: (newStatus) async {
                      final updated = intervention.copyWith(status: newStatus);
                      await provider.updateIntervention(updated);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Moved "${intervention.title}" to ${newStatus.name}',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) {
                      final availableStatuses = InterventionStatus.values
                          .where((status) => status != intervention.status)
                          .toList();

                      return [
                        PopupMenuItem<InterventionStatus>(
                          enabled: false,
                          child: Text(
                            'Move to:',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        PopupMenuDivider(),
                        ...availableStatuses.map((status) {
                          return PopupMenuItem<InterventionStatus>(
                            value: status,
                            child: Text(_getStatusText(status)),
                          );
                        }),
                      ];
                    },
                    icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    intervention.customer.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      intervention.customer.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(intervention.scheduledDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              if (intervention.status == InterventionStatus.inProgress ||
                  intervention.status == InterventionStatus.planned) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: intervention.completionPercentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(intervention.completionPercentage * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showMoveContextMenu(context, details.globalPosition);
      },
      child: cardWidget,
    );
  }

  void _showMoveContextMenu(BuildContext context, Offset position) {
    final availableStatuses = InterventionStatus.values
        .where((status) => status != intervention.status)
        .toList();

    showMenu<InterventionStatus>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem<InterventionStatus>(
          enabled: false,
          child: Text(
            'Move to:',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        PopupMenuDivider(),
        ...availableStatuses.map((status) {
          return PopupMenuItem<InterventionStatus>(
            value: status,
            onTap: () async {
              final updated = intervention.copyWith(status: status);
              await provider.updateIntervention(updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Moved "${intervention.title}" to ${status.name}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(_getStatusText(status)),
          );
        }),
      ],
    );
  }
}
