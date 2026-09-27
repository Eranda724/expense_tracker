import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/expense_providers.dart';
import '../widgets/category_chart.dart';
import '../widgets/expense_tile.dart';
import '../widgets/filter_bar.dart';
import '../widgets/month_summary_card.dart';
import 'add_edit_expense_screen.dart';
import 'insight_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0; // 0 for Home, 1 for Insights

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredExpensesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF2C394B),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 16.0,
                bottom: 0.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.settings, color: Color(0xFF3DF2A4)),
                    color: const Color(0xFF2C394B),
                    onSelected: (value) {
                      if (value == 'theme') {
                        ref.read(themeModeProvider.notifier).toggle();
                      } else if (value == 'logout') {
                        ref.read(authControllerProvider.notifier).signOut();
                      }
                    },
                    itemBuilder: (context) {
                      final isDark =
                          ref.watch(themeModeProvider) == ThemeMode.dark;
                      return [
                        PopupMenuItem(
                          value: 'theme',
                          child: Row(
                            children: [
                              Icon(
                                isDark ? Icons.light_mode : Icons.dark_mode,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDark ? 'Light Mode' : 'Dark Mode',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Wiyafl',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.monetization_on,
                        color: Color(0xFF3DF2A4),
                        size: 22,
                      ),
                      Text(
                        'w',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // Keep title centered
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: MonthSummaryCard(),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B263B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTab = 0);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? const Color(0xFF3DF2A4)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              'Home',
                              style: TextStyle(
                                color: _selectedTab == 0
                                    ? const Color(0xFF0D1512)
                                    : Colors.white,
                                fontWeight: _selectedTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTab = 1);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? const Color(0xFF3DF2A4)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              'Summary',
                              style: TextStyle(
                                color: _selectedTab == 1
                                    ? const Color(0xFF0D1512)
                                    : Colors.white,
                                fontWeight: _selectedTab == 1
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    FilterBar(showOnlyDateFilter: _selectedTab == 1),
                    const SizedBox(height: 8),
                    if (_selectedTab == 0) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: SizedBox(height: 200, child: CategoryChart()),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredAsync.when(
                          data: (expenses) {
                            if (expenses.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No expenses found.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                100,
                              ),
                              itemCount: expenses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) =>
                                  ExpenseTile(expense: expenses[i]),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, st) =>
                              Center(child: Text('Error: $err')),
                        ),
                      ),
                    ] else ...[
                      const InsightTabContent(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 30),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF58D9A3), Color(0xFF28B57D)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3DF2A4).withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, size: 32, color: Color(0xFF0D1512)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
