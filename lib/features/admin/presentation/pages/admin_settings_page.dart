import 'package:flutter/material.dart';
import '../../logic/admin_controller.dart';

class AdminSettingsPage extends StatelessWidget {
  final AdminController adminController;
  const AdminSettingsPage({super.key, required this.adminController});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Account Settings — Coming in Phase 4',
        style: TextStyle(color: Colors.black45),
      ),
    );
  }
}
