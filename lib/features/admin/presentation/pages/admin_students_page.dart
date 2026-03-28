import 'package:flutter/material.dart';
import 'admin_accounts_page.dart';

class AdminStudentsPage extends StatelessWidget {
  const AdminStudentsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const AdminAccountsPage(role: 'student');
}
