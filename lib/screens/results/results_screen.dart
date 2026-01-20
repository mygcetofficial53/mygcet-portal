import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/result_model.dart';
import '../../services/data_service.dart';
import '../../widgets/apple_card.dart';
import '../../widgets/staggered_animation.dart';
import 'gpa_calculator_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<SemesterResult> _gtuResults = DemoResultsData.getResults();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch results when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataService>().fetchMidSemResults();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Academic Results'),
        backgroundColor: isDark ? const Color(0xFF161B22) : AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'GPA Calculator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GpaCalculatorScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Mid Sem 1'),
            Tab(text: 'Mid Sem 2'),
          ],
        ),
      ),
      body: Consumer<DataService>(
        builder: (context, dataService, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMidSemList(dataService.midSem1, isDark),
              _buildMidSemList(dataService.midSem2, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMidSemList(List<MidSemResult> results, bool isDark) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return StaggeredAnimation(
          index: index,
          child: AppleCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.subjectName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.subjectCode,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (result.marks / result.totalMarks) >= 0.4 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                       color: (result.marks / result.totalMarks) >= 0.4 
                        ? Colors.green.withOpacity(0.5) 
                        : Colors.red.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        result.marks.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                           color: (result.marks / result.totalMarks) >= 0.4 
                            ? Colors.green 
                            : Colors.red,
                        ),
                      ),
                      Text(
                        '/ ${result.totalMarks.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // GTU/University results removed as per user request
}

