import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/application/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
            padding: const EdgeInsets.only(bottom: 104),
            children: [
              ListTile(
                leading: const Icon(Icons.star_outline, color: Color(0xFF6366F1)),
                title: const Text(
                  'Upgrade to Pro',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () => context.push(RouteNames.paywall),
              ),
              ListTile(
                leading: Icon(Icons.person_outline, color: Colors.grey[400]),
                title: const Text(
                  'Account',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.notifications_outlined, color: Colors.grey[400]),
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined, color: Colors.grey[400]),
                title: const Text(
                  'Privacy',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.bar_chart_rounded, color: Colors.grey[400]),
                title: const Text(
                  'Charts preview',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Preview charts with mock data',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () => context.push(RouteNames.chartsPreview),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                onTap: () => ref.read(authProvider.notifier).signOut(),
              ),
            ],
          ),
    );
  }
}
