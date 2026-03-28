import 'package:flutter/material.dart';
import 'admin_accounts_page.dart';

class AdminTeachersPage extends StatelessWidget {
  const AdminTeachersPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const AdminAccountsPage(role: 'teacher');
}
