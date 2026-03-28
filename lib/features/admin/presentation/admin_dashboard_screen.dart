import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../logic/admin_controller.dart';
import '../../teacher/presentation/auth_screen.dart';
import 'pages/admin_students_page.dart';
import 'pages/admin_teachers_page.dart';
import 'pages/admin_admins_page.dart';
import 'pages/admin_classes_page.dart';
import 'pages/admin_settings_page.dart';
import '../../../core/controllers/dynamicsize_controller.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminController controller = AdminController();
  int _navIndex = 0;
  bool get _isSidebarLayout => MediaQuery.of(context).size.width >= 700;
  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (controller.signedOut && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen(fromSignOut: true)),
      );
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  static const _navItems = [
    (icon: HugeIcons.strokeRoundedStudents, label: 'Students'),
    (icon: HugeIcons.strokeRoundedTeacher, label: 'Teachers'),
    (icon: HugeIcons.strokeRoundedShieldUser, label: 'Admins'),
    (icon: HugeIcons.strokeRoundedSchoolReportCard, label: 'Classes'),
    (icon: HugeIcons.strokeRoundedSettings01, label: 'Settings'),
  ];
  String get _pageTitle => switch (_navIndex) {
    0 => 'Student Accounts',
    1 => 'Teacher Accounts',
    2 => 'Admin List',
    3 => 'All Classes',
    4 => 'Account Settings',
    _ => '',
  };
  Widget _buildActivePage() => switch (_navIndex) {
    0 => const AdminStudentsPage(),
    1 => const AdminTeachersPage(),
    2 => AdminAdminsPage(adminController: controller),
    3 => const AdminClassesPage(),
    4 => AdminSettingsPage(adminController: controller),
    _ => const SizedBox.shrink(),
  };
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.logout_rounded,
          color: Color(0xFFFBC02D),
          size: 32,
        ),
        title: const Text(
          'Sign Out?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: const Text(
          'You will be signed out of the Admin Dashboard.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.black45),
            child: const Text('Cancel'),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();
              await controller.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const AuthScreen(fromSignOut: true),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) =>
          _isSidebarLayout ? _buildSidebarLayout() : _buildDrawerLayout(),
    );
  }

  Widget _buildSidebarLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: DynamicSizeController.calculateWidthSize(context, 0.07),
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: DynamicSizeController.calculateHeightSize(
                context,
                0.025,
              ),
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedShieldUser,
                color: Colors.white,
                size: DynamicSizeController.calculateAspectRatioSize(
                  context,
                  0.024,
                ),
              ),
            ),
          ),
          SizedBox(
            height: DynamicSizeController.calculateHeightSize(context, 0.02),
          ),
          for (var i = 0; i < _navItems.length; i++)
            _sideNavItem(
              index: i,
              icon: _navItems[i].icon,
              label: _navItems[i].label,
            ),
          const Spacer(),
          GestureDetector(
            onTap: _showSignOutDialog,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: DynamicSizeController.calculateHeightSize(
                    context,
                    0.018,
                  ),
                ),
                child: Column(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedLogout03,
                      color: const Color(0xFFE53935),
                      size: DynamicSizeController.calculateAspectRatioSize(
                        context,
                        0.022,
                      ),
                    ),
                    SizedBox(
                      height: DynamicSizeController.calculateHeightSize(
                        context,
                        0.005,
                      ),
                    ),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: const Color(0xFFE53935),
                        fontSize:
                            DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.011,
                            ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: DynamicSizeController.calculateHeightSize(context, 0.02),
          ),
        ],
      ),
    );
  }

  Widget _sideNavItem({
    required int index,
    required List<List<dynamic>> icon,
    required String label,
  }) {
    final isActive = _navIndex == index;
    const activeColor = Color(0xFF1565C0);
    final color = isActive ? activeColor : Colors.black45;
    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: DynamicSizeController.calculateHeightSize(context, 0.018),
          ),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.08)
                : Colors.transparent,
            border: isActive
                ? const Border(
                    left: BorderSide(color: Color(0xFF1565C0), width: 3),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                color: color,
                size: DynamicSizeController.calculateAspectRatioSize(
                  context,
                  0.022,
                ),
              ),
              SizedBox(
                height: DynamicSizeController.calculateHeightSize(
                  context,
                  0.005,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: DynamicSizeController.calculateAspectRatioSize(
                    context,
                    0.011,
                  ),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: DynamicSizeController.calculateWidthSize(
              context,
              0.025,
            ),
            vertical: DynamicSizeController.calculateHeightSize(context, 0.023),
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        color: const Color(0xFF1565C0),
                        fontSize:
                            DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.009,
                            ),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: DynamicSizeController.calculateWidthSize(
                      context,
                      0.012,
                    ),
                  ),
                  Text(
                    _pageTitle,
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: DynamicSizeController.calculateAspectRatioSize(
                        context,
                        0.018,
                      ),
                    ),
                  ),
                ],
              ),
              if (controller.isLoading)
                SizedBox(
                  width: DynamicSizeController.calculateAspectRatioSize(
                    context,
                    0.014,
                  ),
                  height: DynamicSizeController.calculateAspectRatioSize(
                    context,
                    0.014,
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1565C0),
                  ),
                )
              else
                Text(
                  controller.displayName,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: DynamicSizeController.calculateAspectRatioSize(
                      context,
                      0.013,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _buildActivePage()),
      ],
    );
  }

  Widget _buildDrawerLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _pageTitle,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
        actions: [
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildActivePage(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        controller.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.displayName.isNotEmpty
                              ? controller.displayName
                              : 'Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          controller.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _navItems.length; i++)
              _drawerItem(
                index: i,
                icon: _navItems[i].icon,
                label: _navItems[i].label,
              ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedLogout03,
                color: const Color(0xFFE53935),
                size: 22,
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showSignOutDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required int index,
    required List<List<dynamic>> icon,
    required String label,
  }) {
    final isActive = _navIndex == index;
    const activeColor = Color(0xFF1565C0);
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: isActive ? activeColor : Colors.black54,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? activeColor : Colors.black87,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      tileColor: isActive ? activeColor.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        setState(() => _navIndex = index);
        Navigator.of(context).pop();
      },
    );
  }
}
