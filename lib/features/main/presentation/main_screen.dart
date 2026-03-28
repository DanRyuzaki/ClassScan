import 'package:animate_on_hover/animate_on_hover.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:web/web.dart' as web;
import '../logic/main_controller.dart';
import '../../../core/controllers/dynamicsize_controller.dart';
import '../../teacher/presentation/auth_screen.dart';
import '../../teacher/presentation/dashboard_screen.dart';
import '../../kiosk/presentation/kiosk_screen.dart';
import '../../student/presentation/auth_screen.dart';

const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF111111);
const _border = Color(0xFF1E1E1E);
const _accent = Color(0xFFAEEA00);
const _textPrimary = Color(0xFFF0F0F0);
const _textSecondary = Color(0xFF666666);
const _textMuted = Color(0xFF333333);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final MainController controller = MainController();
  AppPortal _lastPortal = AppPortal.main;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  @override
  void initState() {
    super.initState();
    controller.addListener(_onPortalChanged);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  void _onPortalChanged() {
    final portal = controller.currentPortal;
    if (portal == _lastPortal) return;
    _lastPortal = portal;
    if (portal == AppPortal.main) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handlePortalNavigation(portal);
    });
  }

  Future<void> _handlePortalNavigation(AppPortal portal) async {
    final user = FirebaseAuth.instance.currentUser;
    final isSignedIn = user != null && !user.isAnonymous;
    String? currentRole;
    if (isSignedIn) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        currentRole = doc.data()?['role'] as String?;
      } catch (_) {}
    }
    if (!mounted) return;
    switch (portal) {
      case AppPortal.teacher:
        if (currentRole == 'student') {
          _showRoleConflictDialog(
            'Teacher Portal',
            'student',
            'Student Portal',
          );
          _resetPortal();
          return;
        }
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => isSignedIn && currentRole == 'teacher'
                    ? const DashboardScreen()
                    : AuthScreen(
                        onBack: () {
                          Navigator.of(context).pop();
                          _resetPortal();
                        },
                      ),
              ),
            )
            .then((_) => _resetPortal());
        break;
      case AppPortal.kiosk:
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => KioskScreen(
                  onBack: () {
                    Navigator.of(context).pop();
                    _resetPortal();
                  },
                  onGoToTeacher: () async {
                    final u = FirebaseAuth.instance.currentUser;
                    final signedIn = u != null && !u.isAnonymous;
                    String? role;
                    if (signedIn) {
                      try {
                        final doc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(u.uid)
                            .get();
                        role = doc.data()?['role'] as String?;
                      } catch (_) {}
                    }
                    if (!mounted) return;
                    if (role == 'student') {
                      _showRoleConflictDialog(
                        'Teacher Portal',
                        'student',
                        'Student Portal',
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => signedIn && role == 'teacher'
                            ? const DashboardScreen()
                            : AuthScreen(
                                onBack: () => Navigator.of(context).pop(),
                              ),
                      ),
                    );
                  },
                ),
              ),
            )
            .then((_) => _resetPortal());
        break;
      case AppPortal.student:
        if (currentRole == 'teacher') {
          _showRoleConflictDialog(
            'Student Portal',
            'teacher',
            'Teacher Portal',
          );
          _resetPortal();
          return;
        }
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => StudentAuthScreen(
                  onBack: () {
                    Navigator.of(context).pop();
                    _resetPortal();
                  },
                ),
              ),
            )
            .then((_) => _resetPortal());
        break;
      default:
        break;
    }
  }

  void _showRoleConflictDialog(
    String blocked,
    String role,
    String currentPortal,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        icon: const Icon(
          Icons.block_rounded,
          color: Color(0xFFE53935),
          size: 32,
        ),
        title: const Text(
          'Access Denied',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
            fontSize: 16,
          ),
        ),
        content: Text(
          'You are currently signed in as a $role.\n'
          'Please sign out from the $currentPortal first before accessing the $blocked.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetPortal() {
    _lastPortal = AppPortal.main;
    controller.goToMain();
  }

  @override
  void dispose() {
    controller.removeListener(_onPortalChanged);
    controller.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: _isMobile(context)
              ? _buildMobile(context)
              : _buildDesktop(context),
        ),
      ),
    );
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;
  Widget _buildDesktop(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _QrGridBackground()),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.42,
          child: _buildBrandPanel(context),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.58,
          child: _buildPortalPanel(context),
        ),
        Positioned(
          left: MediaQuery.of(context).size.width * 0.42,
          top: 0,
          bottom: 0,
          width: 1,
          child: Container(color: _border),
        ),
      ],
    );
  }

  Widget _buildBrandPanel(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/icons/favicon.png', width: 52, height: 52),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Class',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: DynamicSizeController.calculateAspectRatioSize(
                      context,
                      0.048,
                    ).clamp(36.0, 64.0),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: 'Scan',
                  style: TextStyle(
                    color: _accent,
                    fontSize: DynamicSizeController.calculateAspectRatioSize(
                      context,
                      0.048,
                    ).clamp(36.0, 64.0),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'QR-Based Web\nSchool Attendance System',
            style: TextStyle(
              color: _textSecondary,
              fontSize: DynamicSizeController.calculateAspectRatioSize(
                context,
                0.013,
              ).clamp(12.0, 16.0),
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Text(
            controller.formattedTime,
            style: TextStyle(
              color: _textPrimary,
              fontSize: DynamicSizeController.calculateAspectRatioSize(
                context,
                0.032,
              ).clamp(28.0, 48.0),
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.formattedDate} · ${controller.timezoneLabel}',
            style: TextStyle(
              color: _textSecondary,
              fontSize: DynamicSizeController.calculateAspectRatioSize(
                context,
                0.011,
              ).clamp(10.0, 14.0),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _socialBtn(
                icon: HugeIcons.strokeRoundedGithub01,
                onTap: () =>
                    web.window.open('https://github.com/DanRyuzaki', '_blank'),
              ),
              const SizedBox(width: 12),
              _socialBtn(
                icon: HugeIcons.strokeRoundedFacebook01,
                onTap: () => web.window.open(
                  'https://www.facebook.com/SoliDeoCode',
                  '_blank',
                ),
              ),
              const SizedBox(width: 12),
              _socialBtn(
                icon: HugeIcons.strokeRoundedGlobe02,
                onTap: () =>
                    web.window.open('https://danryuzaki.is-a.dev', '_blank'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAboutDialog(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'About this project',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                      decorationColor: _textSecondary,
                    ),
                  ),
                ),
              ),
              const Text(
                '  ·  ClassScan © 2026',
                style: TextStyle(color: _textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortalPanel(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT PORTAL',
            style: TextStyle(
              color: _textMuted,
              fontSize: DynamicSizeController.calculateAspectRatioSize(
                context,
                0.010,
              ).clamp(10.0, 13.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your destination\nto continue.',
            style: TextStyle(
              color: _textSecondary,
              fontSize: DynamicSizeController.calculateAspectRatioSize(
                context,
                0.013,
              ).clamp(12.0, 17.0),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          _PortalCard(
            icon: HugeIcons.strokeRoundedTeacher,
            title: 'Teacher Portal',
            subtitle: 'Manage classes, sessions\nand attendance records',
            onTap: controller.goToTeacherPortal,
          ).increaseSizeOnHover(1.03),
          const SizedBox(height: 16),
          _PortalCard(
            icon: HugeIcons.strokeRoundedQrCode,
            title: 'Attendance Scanner',
            subtitle: 'Start a kiosk session\nand scan student QR codes',
            onTap: controller.goToKiosk,
            accent: true,
          ).increaseSizeOnHover(1.03),
          const SizedBox(height: 16),
          _PortalCard(
            icon: HugeIcons.strokeRoundedStudents,
            title: 'Student Portal',
            subtitle: 'View your classes and\naccess your personal QR code',
            onTap: controller.goToStudentPortal,
          ).increaseSizeOnHover(1.03),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(child: _QrGridBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/favicon.png',
                      width: 38,
                      height: 38,
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Class',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: 'Scan',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'QR-Based Web School Attendance System',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'SELECT PORTAL',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                _PortalCard(
                  icon: HugeIcons.strokeRoundedTeacher,
                  title: 'Teacher Portal',
                  subtitle: 'Manage classes, sessions and attendance records',
                  onTap: controller.goToTeacherPortal,
                ),
                const SizedBox(height: 12),
                _PortalCard(
                  icon: HugeIcons.strokeRoundedQrCode,
                  title: 'Attendance Scanner',
                  subtitle: 'Start a kiosk session and scan student QR codes',
                  onTap: controller.goToKiosk,
                  accent: true,
                ),
                const SizedBox(height: 12),
                _PortalCard(
                  icon: HugeIcons.strokeRoundedStudents,
                  title: 'Student Portal',
                  subtitle:
                      'View your classes and access your personal QR code',
                  onTap: controller.goToStudentPortal,
                ),
                const SizedBox(height: 40),
                Text(
                  controller.formattedTime,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${controller.formattedDate} · ${controller.timezoneLabel}',
                  style: const TextStyle(color: _textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _socialBtn(
                      icon: HugeIcons.strokeRoundedGithub01,
                      onTap: () => web.window.open(
                        'https://github.com/DanRyuzaki',
                        '_blank',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _socialBtn(
                      icon: HugeIcons.strokeRoundedFacebook01,
                      onTap: () => web.window.open(
                        'https://www.facebook.com/SoliDeoCode',
                        '_blank',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _socialBtn(
                      icon: HugeIcons.strokeRoundedCoffee01,
                      onTap: () => web.window.open(
                        'https://buymeacoffee.com/danryuzakic',
                        '_blank',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showAboutDialog(context),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: const Text(
                          'About this project',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                            decorationColor: _textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      '  ·  ClassScan © 2026',
                      style: TextStyle(color: _textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: _isMobile(context) ? 20 : 80,
          vertical: _isMobile(context) ? 32 : 60,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(_isMobile(context) ? 24 : 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/favicon.png',
                          width: 36,
                          height: 36,
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Class',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: 'Scan',
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF2A2A2A),
                                ),
                              ),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                color: _textSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A QR-based web attendance system designed to make classroom '
                      'attendance fast, accurate, and effortless for teachers and students.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _aboutDivider(),
                    const SizedBox(height: 20),
                    _aboutLabel('RESEARCH PAPER'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1E1E1E)),
                      ),
                      child: const Text(
                        '"WEB-ASSISTED ATTENDANCE MONITORING SYSTEM WITH '
                        'CLASSROOM-BASED QR SCANNER"',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A paper by Grade 12 STEM 12 1-1P students of Our Lady of Fatima University — Quezon City Campus, Academic Year 2025–2026.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _aboutDivider(),
                    const SizedBox(height: 20),
                    _aboutLabel('RESEARCHERS'),
                    const SizedBox(height: 10),
                    _memberList([
                      'Yulde, Jin Deca R. (Head Proponent)',
                      'Aggabao, Olivia C.',
                      'Añabieza, Maury Joahna B.',
                      'Carmona, Rhevie Yvonne M.',
                      'De Guzman, Princess S.',
                      'Estoque, Francisco Light S.',
                      'Maningas, Sebastian Kaidar M.',
                      'Maragay, Khellie Arvey C.',
                      'Musñgi, Sunshine C.',
                      'Suapengco, Azeriah Jedi V.',
                    ]),
                    const SizedBox(height: 12),
                    _aboutLabel('CONTRIBUTOR & SOLE DEVELOPER'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'SoliDeoCode',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _aboutDivider(),
                    const SizedBox(height: 20),
                    _aboutLabel('OPEN SOURCE'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => web.window.open(
                        'https://github.com/DanRyuzaki/ClassScan',
                        '_blank',
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedGithub01,
                                color: _accent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'github.com/DanRyuzaki/ClassScan',
                                      style: TextStyle(
                                        color: _accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Licensed under Apache 2.0 · Free to use, modify, and distribute',
                                      style: TextStyle(
                                        color: _textSecondary.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowUpRight01,
                                color: _textSecondary,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ClassScan is a non-commercial project. It does not earn from subscriptions, '
                      'ads, or any paid service. It is sustained solely through voluntary donations.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => web.window.open(
                        'https://buymeacoffee.com/danryuzakic',
                        '_blank',
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAEEA00),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCoffee01,
                                color: Colors.black,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Support this project',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _aboutDivider(),
                    const SizedBox(height: 20),
                    _aboutLabel('CONNECT'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _socialBtn(
                          icon: HugeIcons.strokeRoundedGithub01,
                          onTap: () => web.window.open(
                            'https://github.com/DanRyuzaki',
                            '_blank',
                          ),
                        ),
                        const SizedBox(width: 10),
                        _socialBtn(
                          icon: HugeIcons.strokeRoundedFacebook01,
                          onTap: () => web.window.open(
                            'https://www.facebook.com/SoliDeoCode',
                            '_blank',
                          ),
                        ),
                        const SizedBox(width: 10),
                        _socialBtn(
                          icon: HugeIcons.strokeRoundedGlobe02,
                          onTap: () => web.window.open(
                            'https://danryuzaki.is-a.dev',
                            '_blank',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Soli Deo Gloria · ClassScan © 2026',
                        style: TextStyle(color: _textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _aboutDivider() =>
      Container(height: 1, color: const Color(0xFF1A1A1A));
  Widget _aboutLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: _textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.5,
    ),
  );
  Widget _memberList(List<String> members) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: members
        .map(
          (m) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E1E1E)),
            ),
            child: Text(
              m,
              style: const TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ),
        )
        .toList(),
  );
  Widget _socialBtn({
    required List<List<dynamic>> icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Center(
            child: HugeIcon(icon: icon, color: _textSecondary, size: 16),
          ),
        ),
      ),
    );
  }
}

class _PortalCard extends StatefulWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;
  const _PortalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });
  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.accent ? _accent.withValues(alpha: 0.08) : _surface)
                : widget.accent
                ? _accent.withValues(alpha: 0.05)
                : const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? (widget.accent ? _accent : const Color(0xFF2A2A2A))
                  : widget.accent
                  ? _accent.withValues(alpha: 0.3)
                  : _border,
              width: widget.accent ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isMobile ? 40 : 44,
                height: isMobile ? 40 : 44,
                decoration: BoxDecoration(
                  color: _hovered
                      ? (widget.accent
                            ? _accent.withValues(alpha: 0.2)
                            : const Color(0xFF1A1A1A))
                      : widget.accent
                      ? _accent.withValues(alpha: 0.12)
                      : const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.accent
                        ? _accent.withValues(alpha: 0.25)
                        : _border,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: widget.icon,
                    color: widget.accent ? _accent : _textSecondary,
                    size: isMobile ? 20 : 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.accent ? _accent : _textPrimary,
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: isMobile ? 11 : 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: _hovered ? const Offset(0.15, 0) : Offset.zero,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: _hovered
                      ? (widget.accent ? _accent : const Color(0xFF444444))
                      : _textMuted,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrGridBackground extends StatelessWidget {
  const _QrGridBackground();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _QrGridPainter());
  }
}

class _QrGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFAEEA00).withValues(alpha: 0.018)
      ..style = PaintingStyle.fill;
    const cellSize = 28.0;
    const gap = 4.0;
    const step = cellSize + gap;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final dx = (x / size.width - 0.5).abs();
        final dy = (y / size.height - 0.5).abs();
        final dist = (dx + dy);
        final alpha = (0.015 * (1 + dist)).clamp(0.008, 0.03);
        canvas.drawRect(
          Rect.fromLTWH(x, y, 4, 4),
          paint..color = Color.fromRGBO(174, 234, 0, alpha),
        );
      }
    }
    _drawFinderPattern(canvas, size.width - 120, 40, paint);
    _drawFinderPattern(canvas, 40, size.height - 120, paint);
  }

  void _drawFinderPattern(Canvas canvas, double x, double y, Paint paint) {
    final outer = Paint()
      ..color = const Color(0xFFAEEA00).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(Rect.fromLTWH(x, y, 64, 64), outer);
    canvas.drawRect(Rect.fromLTWH(x + 10, y + 10, 44, 44), outer);
    final inner = Paint()
      ..color = const Color(0xFFAEEA00).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x + 20, y + 20, 24, 24), inner);
  }

  @override
  bool shouldRepaint(_QrGridPainter old) => false;
}
