import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:web/web.dart' as web;
import '../logic/auth_controller.dart';
import '../logic/profile_controller.dart';
import 'auth_screen.dart';
import 'pages/dynamic_qr_page.dart';
import 'pages/classes_page.dart';
import 'pages/settings_page.dart';
import '../../../core/controllers/dynamicsize_controller.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});
  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final StudentAuthController _authController = StudentAuthController();
  final StudentProfileController _profileController =
      StudentProfileController();
  int _navIndex = 0;
  bool get _isSidebarLayout => MediaQuery.of(context).size.width >= 700;
  StreamSubscription<DocumentSnapshot>? _sessionWatcher;
  @override
  void initState() {
    super.initState();
    _startSessionWatcher();
  }

  void _startSessionWatcher() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    final localToken = web.window.sessionStorage.getItem(
      'classscan_session_token',
    );
    if (localToken == null || localToken.isEmpty) return;
    _sessionWatcher = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          final firestoreToken = snap.data()?['activeSessionToken'] as String?;
          if (firestoreToken != localToken) {
            _sessionWatcher?.cancel();
            _forceSignOut();
          }
        });
  }

  Future<void> _forceSignOut() async {
    await _authController.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const StudentAuthScreen(fromSignOut: true),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You were signed in on another device. '
            'This session has been ended.',
          ),
          backgroundColor: Color(0xFFE53935),
          duration: Duration(seconds: 6),
        ),
      );
    });
  }

  @override
  void dispose() {
    _sessionWatcher?.cancel();
    _authController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  void _signOut() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedInformationCircle,
          color: const Color(0xFFFBC02D),
          size: 32,
        ),
        title: const Text(
          'Sign Out?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You will be signed out of the Student Portal.',
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
              await _authController.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const StudentAuthScreen(fromSignOut: true),
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

  Widget _buildActivePage() {
    switch (_navIndex) {
      case 0:
        return const StudentQrPage();
      case 1:
        return const StudentClassesPage();
      case 2:
        return const StudentSettingsPage();
      default:
        return const StudentQrPage();
    }
  }

  String get _pageTitle {
    switch (_navIndex) {
      case 0:
        return 'My QR Code';
      case 1:
        return 'My Classes';
      case 2:
        return 'Account Settings';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _profileController,
      builder: (context, _) {
        return _isSidebarLayout ? _buildSidebarLayout() : _buildDrawerLayout();
      },
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

  Widget _buildDrawerLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _pageTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              _profileController.displayName,
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildActivePage(),
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
                colors: [Color(0xFFAEEA00), Color(0xFF76C442)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedStudents,
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
          _navItem(
            index: 0,
            icon: HugeIcons.strokeRoundedQrCode,
            label: 'My QR',
          ),
          _navItem(
            index: 1,
            icon: HugeIcons.strokeRoundedSchoolReportCard,
            label: 'Classes',
          ),
          _navItem(
            index: 2,
            icon: HugeIcons.strokeRoundedSettings01,
            label: 'Settings',
          ),
          const Spacer(),
          GestureDetector(
            onTap: _signOut,
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

  Widget _navItem({
    required int index,
    required List<List<dynamic>> icon,
    required String label,
  }) {
    final isActive = _navIndex == index;
    final color = isActive ? const Color(0xFFAEEA00) : Colors.black45;
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
                ? const Color(0xFFAEEA00).withValues(alpha: 0.08)
                : Colors.transparent,
            border: isActive
                ? const Border(
                    left: BorderSide(color: Color(0xFFAEEA00), width: 3),
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
                  colors: [Color(0xFFAEEA00), Color(0xFF76C442)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _profileController.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileController.displayName.isNotEmpty
                              ? _profileController.displayName
                              : 'Student',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _profileController.email,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(
              index: 0,
              icon: HugeIcons.strokeRoundedQrCode,
              label: 'My QR Code',
            ),
            _drawerItem(
              index: 1,
              icon: HugeIcons.strokeRoundedSchoolReportCard,
              label: 'My Classes',
            ),
            _drawerItem(
              index: 2,
              icon: HugeIcons.strokeRoundedSettings01,
              label: 'Account Settings',
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
              onTap: _signOut,
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
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: isActive ? const Color(0xFF5A8A00) : Colors.black54,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? const Color(0xFF5A8A00) : Colors.black87,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      tileColor: isActive
          ? const Color(0xFFAEEA00).withValues(alpha: 0.1)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        setState(() => _navIndex = index);
        Navigator.of(context).pop();
      },
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
              Text(
                _pageTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: DynamicSizeController.calculateAspectRatioSize(
                    context,
                    0.018,
                  ),
                ),
              ),
              Text(
                _profileController.displayName,
                style: TextStyle(
                  color: Colors.black45,
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
}
