import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../logic/profile_controller.dart';
import '../../../../core/controllers/dynamicsize_controller.dart';

class StudentQrPage extends StatefulWidget {
  const StudentQrPage({super.key});
  @override
  State<StudentQrPage> createState() => _StudentQrPageState();
}

class _StudentQrPageState extends State<StudentQrPage> {
  final StudentProfileController controller = StudentProfileController();
  final GlobalKey _qrKey = GlobalKey();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 700;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall
                ? 20
                : DynamicSizeController.calculateWidthSize(context, 0.06),
            vertical: isSmall
                ? 24
                : DynamicSizeController.calculateHeightSize(context, 0.04),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Text(
                    'My Attendance QR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmall
                          ? 20
                          : DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.020,
                            ),
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Valid for: ${controller.todayDateDisplay}',
                    style: TextStyle(
                      color: const Color(0xFF5A8A00),
                      fontWeight: FontWeight.w600,
                      fontSize: isSmall
                          ? 13
                          : DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.012,
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                HugeIcon(
                                  icon: controller.qrVisible
                                      ? HugeIcons.strokeRoundedView
                                      : HugeIcons.strokeRoundedViewOff,
                                  color: Colors.black54,
                                  size: isSmall
                                      ? 18
                                      : DynamicSizeController.calculateAspectRatioSize(
                                          context,
                                          0.016,
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  controller.qrVisible
                                      ? 'QR Visible'
                                      : 'QR Hidden',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: isSmall
                                        ? 13
                                        : DynamicSizeController.calculateAspectRatioSize(
                                            context,
                                            0.012,
                                          ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: controller.qrVisible,
                              onChanged: (_) => controller.toggleQr(),
                              activeThumbColor: const Color(0xFFAEEA00),
                              activeTrackColor: const Color(
                                0xFFAEEA00,
                              ).withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: controller.qrVisible
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: RepaintBoundary(
                            key: _qrKey,
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(12),
                              child: QrImageView(
                                data: controller.qrPayload,
                                version: QrVersions.auto,
                                size: isSmall
                                    ? 220
                                    : DynamicSizeController.calculateAspectRatioSize(
                                        context,
                                        0.20,
                                      ),
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          secondChild: Container(
                            width: isSmall
                                ? 220
                                : DynamicSizeController.calculateAspectRatioSize(
                                    context,
                                    0.20,
                                  ),
                            height: isSmall
                                ? 220
                                : DynamicSizeController.calculateAspectRatioSize(
                                    context,
                                    0.20,
                                  ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedViewOff,
                                  color: Colors.black26,
                                  size: 40,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Toggle to reveal QR',
                                  style: TextStyle(
                                    color: Colors.black38,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (controller.qrVisible) ...[
                          const SizedBox(height: 16),
                          Text(
                            controller.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFAEEA00,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Valid today only · ${controller.todayDateDisplay}',
                              style: const TextStyle(
                                color: Color(0xFF5A8A00),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedAlertCircle,
                              color: const Color(0xFFF57F17),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Important Notice',
                              style: TextStyle(
                                color: Color(0xFFF57F17),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '• This QR code is personal and must not be shared with anyone.',
                          style: TextStyle(
                            color: Color(0xFF5D4037),
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                        const Text(
                          '• It is valid for today only and will change tomorrow.',
                          style: TextStyle(
                            color: Color(0xFF5D4037),
                            fontSize: 12,
                            height: 1.6,
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
      },
    );
  }
}
