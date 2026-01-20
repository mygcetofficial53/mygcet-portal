import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import 'dart:ui';

class AdminCmsScreen extends StatefulWidget {
  const AdminCmsScreen({super.key});

  @override
  State<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends State<AdminCmsScreen> {
  final _bannerTextController = TextEditingController();
  final _minVersionController = TextEditingController();
  bool _bannerVisible = false;
  String _themeColor = '0xFF3B82F6'; // Default Blue
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await context.read<SupabaseService>().getAppThemeConfig();
    if (mounted) {
      setState(() {
        _bannerTextController.text = config['banner_text'] ?? '';
        _bannerVisible = config['banner_visible'] ?? false;
        _themeColor = config['theme_color'] ?? '0xFF3B82F6';
        _minVersionController.text = config['min_version'] ?? '1.0.0';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    try {
      await context.read<SupabaseService>().updateAppThemeConfig({
        'banner_text': _bannerTextController.text.trim(),
        'banner_visible': _bannerVisible,
        'theme_color': _themeColor,
        'min_version': _minVersionController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App Theme Updated! Users will see changes soon.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('App Customizer (CMS)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: const Color(0xFF0F172A).withOpacity(0.8)),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                children: [
                  _buildSectionHeader('Home Banner'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Show Banner', style: TextStyle(color: Colors.white)),
                          subtitle: const Text('Display a special message on the home screen', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          value: _bannerVisible,
                          onChanged: (v) => setState(() => _bannerVisible = v),
                          activeColor: const Color(0xFF8B5CF6),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                                                TextField(
                          controller: _bannerTextController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Banner Text',
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            hintText: 'e.g., Happy Diwali! 🪔',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _minVersionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Min Supported Version (Force Update)',
                            labelStyle: TextStyle(color: Colors.redAccent.withOpacity(0.9)),
                            hintText: 'e.g., 1.0.0+2002',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.system_update_alt, color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('Theme Preset'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildColorOption('Default Blue', '0xFF3B82F6', Colors.blue),
                        _buildColorOption('Crimson Red', '0xFFDC2626', Colors.red),
                        _buildColorOption('Emerald Green', '0xFF059669', Colors.green),
                        _buildColorOption('Deep Purple', '0xFF7C3AED', Colors.purple),
                        _buildColorOption('Amber Gold', '0xFFD97706', Colors.amber),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save),
                    label: const Text('PUBLISH CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildColorOption(String name, String hex, Color color) {
    final isSelected = _themeColor == hex;
    return InkWell(
      onTap: () => setState(() => _themeColor = hex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 10),
            const SizedBox(width: 12),
            Text(name, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
