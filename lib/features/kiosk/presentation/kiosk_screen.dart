import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toastification/toastification.dart';
import 'package:web/web.dart' as web;
import '../logic/kiosk_controller.dart';
import '../../../core/controllers/dynamicsize_controller.dart';

class KioskScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onGoToTeacher;
  const KioskScreen({super.key, this.onBack, this.onGoToTeacher});
  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  final KioskController controller = KioskController();
  final TextEditingController _classCodeController = TextEditingController();
  bool _isStarting = false;
  static const double _mobileBreak = 700;
  static const double _tabletBreak = 1100;
  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreak;
  bool get _isTablet =>
      MediaQuery.of(context).size.width >= _mobileBreak &&
      MediaQuery.of(context).size.width < _tabletBreak;
  double _fs(double pct) {
    final v = DynamicSizeController.calculateAspectRatioSize(context, pct);
    return _isMobile ? v.clamp(11.0, 20.0) : v;
  }

  double _h(double pct) =>
      DynamicSizeController.calculateHeightSize(context, pct);
  double _w(double pct) =>
      DynamicSizeController.calculateWidthSize(context, pct);
  SessionStatus _lastStatus = SessionStatus.notStarted;
  void _syncControllerState() {
    final status = controller.sessionStatus;
    if (_lastStatus != SessionStatus.notStarted &&
        status == SessionStatus.notStarted) {
      _classCodeController.clear();
    }
    _lastStatus = status;
  }

  @override
  void dispose() {
    controller.dispose();
    _classCodeController.dispose();
    super.dispose();
  }

  void _showLocationWarningToast() {
    toastification.show(
      context: context,
      title: const Text(
        'Location Unavailable',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      description: const Text(
        'Kiosk location could not be determined. '
        'Location validation is disabled for this session — '
        'scans will not be checked for proximity.',
        style: TextStyle(fontSize: 12),
      ),
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedLocation01,
        color: Color(0xFFE65100),
        size: 20,
      ),
      style: ToastificationStyle.flatColored,
      type: ToastificationType.warning,
      autoCloseDuration: const Duration(seconds: 6),
      alignment: Alignment.bottomRight,
      borderRadius: BorderRadius.circular(10),
      showProgressBar: true,
      progressBarTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFE65100),
      ),
    );
  }

  void _showRemoteEndedBanner(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E1E1E)),
        ),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedWifiDisconnected01,
          color: const Color(0xFFE53935),
          size: _isMobile ? 36.0 : _fs(0.036),
        ),
        title: Text(
          'Session Ended Remotely',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFF0F0F0),
            fontWeight: FontWeight.bold,
            fontSize: _isMobile ? 16.0 : _fs(0.018),
          ),
        ),
        content: Text(
          'This session was ended from the Teacher Dashboard.\n'
          'QR scanning has been stopped.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: _isMobile ? 13.0 : _fs(0.013),
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFAEEA00),
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

  void _handleToast(KioskToast toast) {
    final isError = toast.isError;
    final accentColor = isError
        ? const Color(0xFFE53935)
        : const Color(0xFFAEEA00);
    final toastIcon = isError
        ? HugeIcons.strokeRoundedAlertCircle
        : HugeIcons.strokeRoundedInformationCircle;
    toastification.show(
      context: context,
      title: Text(
        toast.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      description: Text(toast.message, style: const TextStyle(fontSize: 12)),
      icon: HugeIcon(icon: toastIcon, color: accentColor, size: 20),
      style: ToastificationStyle.flatColored,
      type: isError ? ToastificationType.error : ToastificationType.info,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.bottomRight,
      borderRadius: BorderRadius.circular(10),
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(color: accentColor),
    );
    controller.clearPendingToast();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncControllerState();
          if (controller.pendingToast != null) {
            _handleToast(controller.pendingToast!);
          }
          if (controller.remotelyEnded) {
            controller.clearRemotelyEnded();
            _showRemoteEndedBanner(context);
          }
          if (controller.kioskLocationWarning) {
            controller.clearKioskLocationWarning();
            _showLocationWarningToast();
          }
        });
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(child: _KioskQrGrid()),
                _isMobile
                    ? _buildMobileLayout(context)
                    : _buildWideLayout(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final panelFraction = _isTablet ? 0.44 : 0.38;
    return Row(
      children: [
        SizedBox(
          width: _w(panelFraction),
          child: _buildControlPanel(context, scrollable: false),
        ),
        Expanded(child: _buildCameraPanel(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: _h(0.42), child: _buildCameraPanel(context)),
        Expanded(child: _buildControlPanel(context, scrollable: true)),
      ],
    );
  }

  Widget _buildControlPanel(BuildContext context, {required bool scrollable}) {
    final isRunning = controller.sessionStatus == SessionStatus.running;
    final hPad = _isMobile ? 20.0 : _w(0.025);
    final vPad = _isMobile ? 20.0 : _h(0.04);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/favicon.png',
                  width: _isMobile ? 28.0 : _fs(0.028).clamp(24.0, 36.0),
                  height: _isMobile ? 28.0 : _fs(0.028).clamp(24.0, 36.0),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Class',
                        style: TextStyle(
                          color: const Color(0xFFF0F0F0),
                          fontSize: _isMobile
                              ? 16.0
                              : _fs(0.016).clamp(13.0, 22.0),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Scan',
                        style: TextStyle(
                          color: const Color(0xFFAEEA00),
                          fontSize: _isMobile
                              ? 16.0
                              : _fs(0.016).clamp(13.0, 22.0),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: widget.onGoToTeacher,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedTeacher,
                    color: const Color(0xFF888888),
                    size: _isMobile ? 20.0 : _fs(0.020).clamp(16.0, 26.0),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _isMobile ? 20.0 : _h(0.045)),
        _buildTextField(
          context: context,
          hint: 'Enter Class Code',
          enabled: !isRunning,
          textController: _classCodeController,
          onChanged: controller.updateClassCode,
        ),
        SizedBox(height: _isMobile ? 12.0 : _h(0.014)),
        _buildTextField(
          context: context,
          hint: 'Teacher',
          enabled: false,
          value: controller.isTeacherVerified ? controller.teacherName : null,
          suffixIcon: HugeIcons.strokeRoundedQrCode,
        ),
        SizedBox(height: _isMobile ? 4.0 : _h(0.008)),
        Text(
          'for teachers, scan your QR code.',
          style: TextStyle(
            color: const Color(0xFF555555),
            fontSize: _fs(0.010).clamp(10.0, 13.0),
          ),
        ),
        SizedBox(height: _isMobile ? 20.0 : _h(0.04)),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRunning
                    ? const Color(0xFFAEEA00)
                    : const Color(0xFF2A2A2A),
                boxShadow: isRunning
                    ? [
                        BoxShadow(
                          color: const Color(0xFFAEEA00).withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Session: ${controller.sessionStatusLabel}',
              style: TextStyle(
                color: const Color(0xFF888888),
                fontSize: _fs(0.012).clamp(11.0, 14.0),
              ),
            ),
          ],
        ),
        SizedBox(height: _isMobile ? 12.0 : _h(0.014)),
        _buildSessionButton(context, isRunning),
        scrollable
            ? SizedBox(height: _isMobile ? 28.0 : _h(0.04))
            : const Spacer(),
        Text(
          controller.formattedTime,
          style: TextStyle(
            color: const Color(0xFFF0F0F0),
            fontSize: _isMobile ? 30.0 : _fs(0.026).clamp(22.0, 40.0),
            fontWeight: FontWeight.w300,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: _isMobile ? 2.0 : _h(0.004)),
        Text(
          controller.formattedDate,
          style: TextStyle(
            color: const Color(0xFF555555),
            fontSize: _isMobile ? 11.0 : _fs(0.010).clamp(10.0, 13.0),
            letterSpacing: 0.2,
          ),
        ),
        if (scrollable) const SizedBox(height: 24),
      ],
    );
    if (scrollable) {
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: content,
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: content,
    );
  }

  Widget _buildSessionButton(BuildContext context, bool isRunning) {
    final gradient = isRunning
        ? const LinearGradient(
            colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final bool blocked =
        _isStarting || controller.sessionStatus == SessionStatus.ended;
    return GestureDetector(
      onTap: blocked
          ? null
          : () async {
              if (isRunning) {
                _showEndSessionDialog(context);
              } else {
                final selection = await _showCameraPickerDialog(context);
                if (selection == null) return;
                setState(() => _isStarting = true);
                await controller.startSession(cameraFacing: selection.facing);
                if (mounted) setState(() => _isStarting = false);
              }
            },
      child: MouseRegion(
        cursor: blocked ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: blocked ? 0.6 : 1.0,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: _isMobile ? 14.0 : _h(0.016),
            ),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: blocked
                ? SizedBox(
                    width: _isMobile ? 18.0 : _fs(0.016),
                    height: _isMobile ? 18.0 : _fs(0.016),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isRunning ? 'End Session' : 'Start Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: _isMobile ? 14.0 : _fs(0.013),
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPanel(BuildContext context) {
    final margin = _isMobile ? 10.0 : _fs(0.025);
    final radius = _isMobile ? 12.0 : _fs(0.018);
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                margin: EdgeInsets.all(margin),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(radius),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    controller.isCameraActive &&
                        controller.scannerController != null
                    ? MobileScanner(
                        controller: controller.scannerController!,
                        onDetect: controller.onQrDetected,
                      )
                    : _buildCameraPlaceholder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedQrCode,
              color: Colors.white12,
              size: _isMobile ? 48.0 : _fs(0.07),
            ),
            SizedBox(height: _isMobile ? 10.0 : _h(0.014)),
            Text(
              'Camera must be available\nto begin a session.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white24,
                fontSize: _isMobile ? 11.0 : _fs(0.011),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<_CameraSelection?> _showCameraPickerDialog(
    BuildContext context,
  ) async {
    final options = [
      _CameraOption(
        facing: null,
        label: 'System Default',
        sublabel:
            'Uses the device default camera — recommended for laptops '
            'and USB webcams',
        icon: HugeIcons.strokeRoundedComputerEthernet,
      ),
      _CameraOption(
        facing: CameraFacing.back,
        label: 'Back Camera',
        sublabel: 'Environment-facing — best for a mounted tablet kiosk',
        icon: HugeIcons.strokeRoundedCamera01,
      ),
      _CameraOption(
        facing: CameraFacing.front,
        label: 'Front Camera',
        sublabel: 'User-facing — best for a handheld or tablet kiosk',
        icon: HugeIcons.strokeRoundedCamera02,
      ),
    ];
    _CameraSelection? selected;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E1E1E)),
          ),
          title: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                color: const Color(0xFFAEEA00),
                size: _isMobile ? 22.0 : _fs(0.022).clamp(18.0, 26.0),
              ),
              const SizedBox(width: 10),
              Text(
                'Select Camera',
                style: TextStyle(
                  color: const Color(0xFFF0F0F0),
                  fontWeight: FontWeight.w700,
                  fontSize: _isMobile ? 15.0 : _fs(0.016).clamp(13.0, 18.0),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose a camera for this session. '
                'This cannot be changed once the session starts.',
                style: TextStyle(
                  color: const Color(0xFF666666),
                  fontSize: _isMobile ? 12.0 : _fs(0.012).clamp(11.0, 13.0),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = selected?.facing == opt.facing;
                return GestureDetector(
                  onTap: () =>
                      setD(() => selected = _CameraSelection(opt.facing)),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFAEEA00).withValues(alpha: 0.08)
                            : const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFAEEA00).withValues(alpha: 0.5)
                              : const Color(0xFF1E1E1E),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: opt.icon,
                            color: isSelected
                                ? const Color(0xFFAEEA00)
                                : const Color(0xFF555555),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFFAEEA00)
                                        : const Color(0xFFF0F0F0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.sublabel,
                                  style: const TextStyle(
                                    color: Color(0xFF555555),
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                              color: Color(0xFFAEEA00),
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () {
                selected = null;
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF555555),
              ),
              child: const Text('Cancel'),
            ),
            GestureDetector(
              onTap: selected == null
                  ? null
                  : () => Navigator.of(context).pop(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: selected == null ? 0.35 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAEEA00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Start Session',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return selected;
  }

  void _showEndSessionDialog(BuildContext context) {
    if (controller.isTeacherVerified) {
      _showVerifiedEndDialog(context);
    } else {
      _showUnverifiedEndDialog(context);
    }
  }

  void _showVerifiedEndDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E1E1E)),
        ),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedInformationCircle,
          color: const Color(0xFFFBC02D),
          size: _isMobile ? 32.0 : _fs(0.032),
        ),
        title: Text(
          'Are you sure?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF0F0F0),
            fontSize: _isMobile ? 16.0 : _fs(0.018),
          ),
        ),
        content: Text(
          'Once the session ends, you will not be able to resume it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: _isMobile ? 13.0 : _fs(0.013),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF555555),
            ),
            child: const Text('Cancel'),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();
              await controller.endSession();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'End Session',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: _isMobile ? 13.0 : _fs(0.013),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnverifiedEndDialog(BuildContext context) {
    bool hasDownloaded = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF111111),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF1E1E1E)),
            ),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: const Color(0xFFE53935),
              size: _isMobile ? 32.0 : _fs(0.032),
            ),
            title: Text(
              'Teacher Not Verified',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF0F0F0),
                fontSize: _isMobile ? 15.0 : _fs(0.018),
              ),
            ),
            content: SizedBox(
              width: _isMobile ? double.maxFinite : 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "The teacher's QR was not scanned. "
                    'This session will NOT be saved to the dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: _isMobile ? 13.0 : _fs(0.013),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You must download the attendance file before ending.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                      fontSize: _isMobile ? 12.0 : _fs(0.012),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: hasDownloaded
                        ? null
                        : () {
                            _exportUnverifiedAttendance(context);
                            setDialogState(() => hasDownloaded = true);
                          },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: hasDownloaded ? 0.5 : 1.0,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: hasDownloaded
                                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                                  : HugeIcons.strokeRoundedFileExport,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasDownloaded
                                  ? 'Downloaded ✓'
                                  : 'Download Attendance',
                              style: const TextStyle(
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
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              GestureDetector(
                onTap: hasDownloaded
                    ? () async {
                        Navigator.of(context).pop();
                        await controller.endSession(deleteUnverified: true);
                      }
                    : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: hasDownloaded ? 1.0 : 0.35,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'End Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportUnverifiedAttendance(BuildContext context) {
    final rows = controller.getScannedStudentsExport();
    if (rows.isEmpty) return;
    final buffer = StringBuffer();
    buffer.writeln('Name,Time In,Time Out,Status,Remark');
    for (final row in rows) {
      buffer.writeln(
        '${row['Name']},${row['Time In']},${row['Time Out']},'
        '${row['Status']},${row['Remark']}',
      );
    }
    final cls = controller.classCode;
    final date = controller.formattedDate.split(',').first.trim();
    final filename = 'Attendance_${cls}_${date}_Unverified.csv';
    _downloadFile(
      content: buffer.toString(),
      filename: filename,
      mimeType: 'text/csv',
    );
  }

  void _downloadFile({
    required String content,
    required String filename,
    required String mimeType,
  }) {
    final bytes = Uint8List.fromList(content.codeUnits);
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.document.createElement('a') as web.HTMLAnchorElement;
    a.href = url;
    a.setAttribute('download', filename);
    web.document.body!.append(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
  }

  Widget _buildTextField({
    required BuildContext context,
    required String hint,
    required bool enabled,
    String? value,
    TextEditingController? textController,
    ValueChanged<String>? onChanged,
    List<List<dynamic>>? suffixIcon,
  }) {
    final effectiveController =
        textController ?? TextEditingController(text: value ?? '');
    final fontSize = _isMobile ? 13.0 : _fs(0.012);
    final vPad = _isMobile ? 14.0 : _h(0.014);
    final hPad = _isMobile ? 14.0 : _w(0.012);
    return TextField(
      controller: effectiveController,
      enabled: enabled,
      onChanged: onChanged,
      style: TextStyle(color: const Color(0xFFF0F0F0), fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xFF444444),
          fontSize: fontSize,
        ),
        filled: true,
        fillColor: const Color(0xFF111111),
        contentPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF1E1E1E)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF161616)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFAEEA00)),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 10),
                child: HugeIcon(
                  icon: suffixIcon,
                  color: const Color(0xFF444444),
                  size: _isMobile ? 18.0 : _fs(0.016),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

class _CameraSelection {
  final CameraFacing? facing;
  const _CameraSelection(this.facing);
}

class _CameraOption {
  final CameraFacing? facing;
  final String label;
  final String sublabel;
  final List<List<dynamic>> icon;
  const _CameraOption({
    required this.facing,
    required this.label,
    required this.sublabel,
    required this.icon,
  });
}

class _KioskQrGrid extends StatelessWidget {
  const _KioskQrGrid();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _KioskQrGridPainter());
}

class _KioskQrGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final dx = (x / size.width - 0.5).abs();
        final dy = (y / size.height - 0.5).abs();
        final alpha = (0.010 * (1 + dx + dy)).clamp(0.005, 0.020);
        canvas.drawRect(
          Rect.fromLTWH(x, y, 4, 4),
          Paint()..color = Color.fromRGBO(174, 234, 0, alpha),
        );
      }
    }
    _drawFinder(canvas, 32, size.height - 110);
    _drawFinder(canvas, size.width - 110, size.height - 110);
  }

  void _drawFinder(Canvas canvas, double x, double y) {
    final stroke = Paint()
      ..color = const Color(0xFFAEEA00).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(x, y, 56, 56), stroke);
    canvas.drawRect(Rect.fromLTWH(x + 9, y + 9, 38, 38), stroke);
    canvas.drawRect(
      Rect.fromLTWH(x + 18, y + 18, 20, 20),
      Paint()..color = const Color(0xFFAEEA00).withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(_KioskQrGridPainter old) => false;
}
