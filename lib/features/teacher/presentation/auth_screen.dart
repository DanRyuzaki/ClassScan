import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import '../logic/auth_controller.dart';
import '../presentation/dashboard_screen.dart';
import '../../../core/controllers/dynamicsize_controller.dart';

const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF111111);
const _border = Color(0xFF1E1E1E);
const _accent = Color(0xFFAEEA00);
const _textPrimary = Color(0xFFF0F0F0);
const _textSecondary = Color(0xFF666666);
const _textMuted = Color(0xFF333333);

class AuthScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool fromSignOut;
  const AuthScreen({super.key, this.onBack, this.fromSignOut = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthController controller = AuthController();
  bool _isNavigating = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  bool get _isMobile => MediaQuery.of(context).size.width < 700;
  double _fs(double pct, {double min = 11, double max = 28}) =>
      DynamicSizeController.calculateAspectRatioSize(
        context,
        pct,
      ).clamp(min, max);
  double _w(double pct, {double min = 8, double max = 2000}) =>
      DynamicSizeController.calculateWidthSize(context, pct).clamp(min, max);
  double _h(double pct, {double min = 4, double max = 2000}) =>
      DynamicSizeController.calculateHeightSize(context, pct).clamp(min, max);
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    if (!widget.fromSignOut) _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    if (_isNavigating) return;
    final isTeacher = await controller.isSignedInAsTeacher();
    if (isTeacher && mounted && !_isNavigating) _goToDashboard();
  }

  void _goToDashboard() {
    if (_isNavigating) return;
    _isNavigating = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    controller.dispose();
    super.dispose();
  }

  void _showToast({
    required String title,
    required String message,
    bool isError = false,
  }) {
    final color = isError ? const Color(0xFFE53935) : _accent;
    toastification.show(
      context: context,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      description: Text(message, style: const TextStyle(fontSize: 12)),
      icon: HugeIcon(
        icon: isError
            ? HugeIcons.strokeRoundedAlertCircle
            : HugeIcons.strokeRoundedCheckmarkCircle02,
        color: color,
        size: 20,
      ),
      style: ToastificationStyle.flatColored,
      type: isError ? ToastificationType.error : ToastificationType.success,
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.bottomRight,
      borderRadius: BorderRadius.circular(10),
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(color: color),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isNavigating) return;
    final success = await controller.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      _showToast(title: 'Welcome!', message: 'Signed in successfully.');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _goToDashboard();
    } else if (controller.errorMessage != null) {
      _showToast(
        title: 'Sign-in Failed',
        message: controller.errorMessage!,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(child: _QrGridBackground()),
                _isMobile ? _buildMobile() : _buildDesktop(),
                if (controller.isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: const Center(
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.42,
          child: _buildBrandPanel(),
        ),
        Container(width: 1, color: _border),
        Expanded(child: _buildSignInPanel()),
      ],
    );
  }

  Widget _buildBrandPanel() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _w(0.04, min: 32),
        vertical: 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.of(context).pop(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: _textSecondary,
                    size: _fs(0.016, min: 14, max: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: _fs(0.012, min: 11, max: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Image.asset('assets/icons/favicon.png', width: 56, height: 56),
          SizedBox(height: _h(0.02, min: 16)),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Class',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: _fs(0.042, min: 32, max: 58),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: 'Scan',
                  style: TextStyle(
                    color: _accent,
                    fontSize: _fs(0.042, min: 32, max: 58),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _h(0.010, min: 8)),
          Text(
            'QR-Based Web\nSchool Attendance System',
            style: TextStyle(
              color: _textSecondary,
              fontSize: _fs(0.012, min: 11, max: 15),
              height: 1.6,
            ),
          ),
          SizedBox(height: _h(0.018, min: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _accent.withValues(alpha: 0.25)),
            ),
            child: Text(
              'TEACHER PORTAL',
              style: TextStyle(
                color: _accent,
                fontSize: _fs(0.010, min: 10, max: 12),
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'ClassScan © 2026',
            style: TextStyle(
              color: _textMuted,
              fontSize: _fs(0.010, min: 10, max: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPanel() {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: _w(0.04, min: 32)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SIGN IN',
                style: TextStyle(
                  color: const Color(0xFFAAAAAA),
                  fontSize: _fs(0.010, min: 10, max: 12),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              SizedBox(height: _h(0.008, min: 6)),
              Text(
                'Access your teacher\ndashboard.',
                style: TextStyle(
                  color: const Color(0xFF1A1A1A),
                  fontSize: _fs(0.014, min: 13, max: 18),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: _h(0.05, min: 32)),
              _buildGoogleButton(),
              SizedBox(height: _h(0.025, min: 16)),
              Container(
                padding: EdgeInsets.all(_fs(0.012, min: 12, max: 16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      color: const Color(0xFFAAAAAA),
                      size: _fs(0.014, min: 13, max: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use your institutional Google account. '
                        'Student accounts will be rejected.',
                        style: TextStyle(
                          color: const Color(0xFF888888),
                          fontSize: _fs(0.011, min: 11, max: 13),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom -
              56,
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: _textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Back',
                        style: TextStyle(color: _textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Image.asset(
                    'assets/icons/favicon.png',
                    width: 40,
                    height: 40,
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
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _accent.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'TEACHER PORTAL',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'SIGN IN',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Access your teacher dashboard.',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildGoogleButton(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      color: _textSecondary,
                      size: 15,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use your institutional Google account. Student accounts will be rejected.',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'ClassScan © 2026',
                  style: TextStyle(color: _textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: controller.isLoading ? null : _handleGoogleSignIn,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: _isMobile ? 14 : _h(0.016, min: 14, max: 20),
          ),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              else ...[
                HugeIcon(
                  icon: HugeIcons.strokeRoundedGoogle,
                  color: Colors.black,
                  size: _isMobile ? 18 : _fs(0.016, min: 16, max: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sign in with Google',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: _isMobile ? 14 : _fs(0.013, min: 13, max: 15),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
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
  Widget build(BuildContext context) => CustomPaint(painter: _QrGridPainter());
}

class _QrGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final dx = (x / size.width - 0.5).abs();
        final dy = (y / size.height - 0.5).abs();
        final alpha = (0.012 * (1 + dx + dy)).clamp(0.006, 0.025);
        canvas.drawRect(
          Rect.fromLTWH(x, y, 4, 4),
          Paint()..color = Color.fromRGBO(174, 234, 0, alpha),
        );
      }
    }
    _drawFinder(canvas, size.width - 110, 32);
    _drawFinder(canvas, 32, size.height - 110);
  }

  void _drawFinder(Canvas canvas, double x, double y) {
    final stroke = Paint()
      ..color = const Color(0xFFAEEA00).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(Rect.fromLTWH(x, y, 60, 60), stroke);
    canvas.drawRect(Rect.fromLTWH(x + 10, y + 10, 40, 40), stroke);
    canvas.drawRect(
      Rect.fromLTWH(x + 20, y + 20, 20, 20),
      Paint()..color = const Color(0xFFAEEA00).withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(_QrGridPainter old) => false;
}
