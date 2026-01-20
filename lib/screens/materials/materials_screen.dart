import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../models/other_models.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/liquid_loading.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  String _searchQuery = '';
  bool _isRefreshing = false;
  String? _selectedCategory;
  String? _selectedSubject;
  bool _isSearching = false;
  final TextEditingController _courseSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch initial dropdowns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _courseSearchController.dispose();
    super.dispose();
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'video':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    final authService = context.read<AuthService>();
    final dataService = context.read<DataService>();
    dataService.setGmsService(authService.gmsService);
    // Pass student so registered courses can populate subjects dropdown
    await dataService.fetchMaterials(student: authService.currentUser);
    setState(() => _isRefreshing = false);
  }

  Future<void> _searchMaterials() async {
    final courseQuery = _courseSearchController.text.trim();
    
    // Prefer text search if query is provided
    if (courseQuery.isNotEmpty) {
      setState(() => _isSearching = true);
      final authService = context.read<AuthService>();
      final dataService = context.read<DataService>();
      dataService.setGmsService(authService.gmsService);
      await dataService.searchMaterialsByText(courseQuery, category: _selectedCategory);
      setState(() => _isSearching = false);
      return;
    }
    
    // Use subject dropdown selection as filtered search
    if (_selectedSubject != null) {
      setState(() => _isSearching = true);
      final authService = context.read<AuthService>();
      final dataService = context.read<DataService>();
      dataService.setGmsService(authService.gmsService);
      // Use filter search: Category (optional) + Subject (Course Code)
      await dataService.searchMaterialsByFilter(_selectedCategory, _selectedSubject!);
      setState(() => _isSearching = false);
      return;
    }
    
    // No search criteria provided
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter course code/name or select a subject')),
    );
  }

  List<StudyMaterial> _filterMaterials(List<StudyMaterial> materials) {
    if (_searchQuery.isEmpty) return materials;
    final query = _searchQuery.toLowerCase();
    return materials.where((m) {
      return m.title.toLowerCase().contains(query) ||
          m.subjectName.toLowerCase().contains(query) ||
          m.subjectCode.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: Consumer<DataService>(
        builder: (context, dataService, child) {
          final categories = dataService.materialCategories;
          final subjects = dataService.materialSubjects;
          final allMaterials = dataService.materials;
          final filteredMaterials = _filterMaterials(allMaterials);
          
          // Validation: Ensure _selectedSubject exists in subjects list
          if (_selectedSubject != null && !subjects.any((s) => s.value == _selectedSubject)) {
             // If subject not found (e.g. data refresh), reset selection
             // This prevents the "There should be exactly one item..." crash
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (context.mounted) {
                 setState(() => _selectedSubject = null);
               }
             });
          }

          // Group by subject
          final grouped = <String, List<StudyMaterial>>{};
          for (var material in filteredMaterials) {
            grouped.putIfAbsent(material.subjectName, () => []).add(material);
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.search, color: AppTheme.primaryBlue),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Search Materials',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                            // Category Dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.grey.shade200,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category (Optional)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.category_outlined, size: 20),
                              ),
                              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Categories')),
                                ...categories.map((c) => DropdownMenuItem(
                                  value: c.value,
                                  child: Text(
                                    c.name, 
                                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedCategory = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Course Code / Name Search Field (NEW)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                               border: Border.all(
                                color: isDark ? Colors.white10 : Colors.grey.shade200,
                              ),
                            ),
                            child: TextField(
                              controller: _courseSearchController,
                              decoration: InputDecoration(
                                labelText: 'Course Code or Name',
                                hintText: 'e.g., CS101 or Data Structures',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                prefixIcon: const Icon(Icons.search_outlined, size: 20),
                                suffixIcon: _courseSearchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _courseSearchController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // OR divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white54 : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Subject Dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.grey.shade200,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedSubject,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select Subject',
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.book_outlined, size: 20),
                              ),
                              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('-- Select Subject --')),
                                ...subjects.map((s) => DropdownMenuItem(
                                  value: s.value,
                                  child: Text(
                                    s.name.length > 40 ? '${s.name.substring(0, 40)}...' : s.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedSubject = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Search Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSearching ? null : _searchMaterials,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                              ),
                              child: _isSearching 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_rounded),
                                        SizedBox(width: 8),
                                        Text('Search Materials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Loading indicator
                    if ((dataService.isLoading || _isSearching) && allMaterials.isEmpty)
                      const ShimmerLoading(type: ShimmerType.list),

                    // Materials List
                    if (!dataService.isLoading && !_isSearching)
                      if (grouped.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.library_books_rounded,
                                  size: 80,
                                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Materials Found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Search for a subject to view materials',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                'Results',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            ...grouped.entries.map((entry) {
                              return _SubjectExpansionTile(
                                subject: entry.key,
                                materials: entry.value,
                                getFileIcon: _getFileIcon,
                                getFileColor: _getFileColor,
                                isDark: isDark,
                              );
                            }),
                          ],
                        ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubjectExpansionTile extends StatelessWidget {
  final String subject;
  final List<StudyMaterial> materials;
  final IconData Function(String) getFileIcon;
  final Color Function(String) getFileColor;
  final bool isDark;

  const _SubjectExpansionTile({
    required this.subject,
    required this.materials,
    required this.getFileIcon,
    required this.getFileColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white12 : Colors.transparent),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          childrenPadding: const EdgeInsets.all(0),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue, 
                  AppTheme.primaryBlue.withOpacity(0.7)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.folder_copy_rounded, color: Colors.white, size: 24),
          ),
          title: Text(
            subject,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF2D3748),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.description_outlined, 
                  size: 14, 
                  color: isDark ? Colors.white54 : Colors.grey.shade500
                ),
                const SizedBox(width: 4),
                Text(
                  '${materials.length} files available',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              height: 1, 
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            ),
            ...materials.map((material) {
              return _MaterialListItem(
                material: material,
                icon: getFileIcon(material.type),
                color: getFileColor(material.type),
                isDark: isDark,
              );
            }).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MaterialListItem extends StatelessWidget {
  final StudyMaterial material;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MaterialListItem({
    required this.material,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  Future<void> _downloadMaterial(BuildContext context) async {
    if (material.url != null && material.url!.isNotEmpty) {
      try {
        final urlString = material.url!;
        debugPrint('MaterialsScreen: Opening download URL: $urlString');
        
        final uri = Uri.parse(urlString);
        
        // Try to launch directly - canLaunchUrl often returns false for HTTP URLs
        try {
          final launched = await launchUrl(
            uri, 
            mode: LaunchMode.externalApplication,
          );
          
          if (!launched) {
            // Fallback: Try with platform default mode
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        } catch (launchError) {
          debugPrint('MaterialsScreen: launchUrl failed: $launchError');
          // Show the URL so user can copy it manually
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open link. URL: $urlString'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Copy',
                  onPressed: () {
                    // Copy URL to clipboard
                    // Clipboard.setData(ClipboardData(text: urlString));
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('MaterialsScreen: Error parsing URL: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else {
      debugPrint('MaterialsScreen: No download URL available for this material');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download link not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _downloadMaterial(context),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          material.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3748),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  material.uploadedBy,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                material.uploadedAt,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.download_rounded,
            color: AppTheme.primaryBlue,
            size: 18,
          ),
        ),
      ),
    );
  }
}
