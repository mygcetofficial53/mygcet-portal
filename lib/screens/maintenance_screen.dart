import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 80, color: Colors.amberAccent.withOpacity(0.8)),
            const SizedBox(height: 24),
            const Text(
              'Under Maintenance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We are currently performing scheduled maintenance to improve your experience. Please check back later.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Optional: Contact Support or Retry button
            OutlinedButton.icon(
              onPressed: () {
                // Just for visual feedback, usually app restart is needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Still under maintenance...')),
                );
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Check Status', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
