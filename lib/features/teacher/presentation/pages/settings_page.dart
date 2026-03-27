import 'dart:js_interop';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:hugeicons/hugeicons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:web/web.dart' as web;
import '../../logic/settings_controller.dart';
import '../../../../core/controllers/dynamicsize_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsController controller = SettingsController();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _lastNameCtrl;
  String _selectedEmoji = '🧑‍🏫';
  final GlobalKey _qrKey = GlobalKey();
  final List<String> _emojis = [
    '🧑‍🏫',
    '👩‍🏫',
    '👨‍🏫',
    '🎓',
    '📚',
    '✏️',
    '🧑‍💻',
    '👩‍💻',
    '👨‍💻',
    '🔬',
    '🧪',
    '📐',
    '🎨',
    '🎭',
    '🏫',
    '📝',
    '💡',
    '🌟',
  ];
  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _middleNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (controller.status == SettingsStatus.idle &&
        _firstNameCtrl.text.isEmpty &&
        controller.firstName.isNotEmpty) {
      _firstNameCtrl.text = controller.firstName;
      _middleNameCtrl.text = controller.middleName;
      _lastNameCtrl.text = controller.lastName;
      setState(() => _selectedEmoji = controller.emoji);
    }
    if (controller.status == SettingsStatus.success &&
        controller.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showToast(title: 'Saved', message: controller.successMessage!);
          controller.clearStatus();
        }
      });
    } else if (controller.status == SettingsStatus.error &&
        controller.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showToast(
            title: 'Error',
            message: controller.errorMessage!,
            isError: true,
          );
          controller.clearStatus();
        }
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _showToast({
    required String title,
    required String message,
    bool isError = false,
  }) {
    final color = isError ? const Color(0xFFE53935) : const Color(0xFFAEEA00);
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
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.bottomRight,
      borderRadius: BorderRadius.circular(10),
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(color: color),
    );
  }

  void _showRegenerateDialog(BuildContext context) {
    final random = Random();
    final a = random.nextInt(9) + 1;
    final b = random.nextInt(9) + 1;
    final answer = (a + b).toString();
    final inputCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedRefresh,
            color: const Color(0xFFE53935),
            size: 30,
          ),
          title: const Text(
            'Regenerate QR Code?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE53935),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only regenerate if your QR code was leaked or '
                        'compromised.\nYour old QR will immediately stop '
                        'working and any unauthorized person holding it '
                        'will no longer be able to verify sessions.',
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'To confirm, answer this: $a + $b = ?',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: inputCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (_) => setD(() {}),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '?',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE53935),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                inputCtrl.dispose();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
              child: const Text('Cancel'),
            ),
            GestureDetector(
              onTap: inputCtrl.text.trim() == answer
                  ? () async {
                      Navigator.of(ctx).pop();
                      inputCtrl.dispose();
                      final error = await controller.regenerateQrToken();
                      if (!mounted) return;
                      if (error != null) {
                        toastification.show(
                          // ignore: use_build_context_synchronously
                          context: context,
                          title: const Text(
                            'Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          description: Text(
                            error,
                            style: const TextStyle(fontSize: 12),
                          ),
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedAlertCircle,
                            color: Color(0xFFE53935),
                            size: 20,
                          ),
                          style: ToastificationStyle.flatColored,
                          type: ToastificationType.error,
                          autoCloseDuration: const Duration(seconds: 4),
                          alignment: Alignment.bottomRight,
                          borderRadius: BorderRadius.circular(10),
                          showProgressBar: true,
                        );
                      } else {
                        toastification.show(
                          // ignore: use_build_context_synchronously
                          context: context,
                          title: const Text(
                            'QR Code Regenerated',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          description: const Text(
                            'Your old QR code is now invalid. '
                            'Download the new one from Settings.',
                            style: TextStyle(fontSize: 12),
                          ),
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                            color: Color(0xFFAEEA00),
                            size: 20,
                          ),
                          style: ToastificationStyle.flatColored,
                          type: ToastificationType.success,
                          autoCloseDuration: const Duration(seconds: 5),
                          alignment: Alignment.bottomRight,
                          borderRadius: BorderRadius.circular(10),
                          showProgressBar: true,
                        );
                      }
                    }
                  : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: inputCtrl.text.trim() == answer ? 1.0 : 0.35,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
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
                    'Regenerate',
                    style: TextStyle(
                      color: Colors.white,
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
    ).then((_) {
      inputCtrl.dispose();
    });
  }

  Future<void> _saveQrImage() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final uint8 = byteData.buffer.asUint8List();
      final blob = web.Blob(
        [uint8.toJS].toJS,
        web.BlobPropertyBag(type: 'image/png'),
      );
      final url = web.URL.createObjectURL(blob);
      final a = web.document.createElement('a') as web.HTMLAnchorElement;
      a.href = url;
      a.setAttribute(
        'download',
        'TeacherQR_${controller.displayName.replaceAll(' ', '_')}.png',
      );
      web.document.body!.append(a);
      a.click();
      a.remove();
      web.URL.revokeObjectURL(url);
      _showToast(title: 'QR Saved', message: 'QR code image downloaded.');
    } catch (e) {
      debugPrint('saveQrImage error: $e');
      _showToast(
        title: 'Error',
        message: 'Could not save QR image.',
        isError: true,
      );
    }
  }

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Choose Profile Emoji',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DynamicSizeController.calculateAspectRatioSize(
              context,
              0.016,
            ),
          ),
        ),
        content: SizedBox(
          width: DynamicSizeController.calculateWidthSize(context, 0.28),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _emojis.map((emoji) {
              final isSelected = emoji == _selectedEmoji;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedEmoji = emoji);
                  Navigator.of(context).pop();
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFAEEA00).withValues(alpha: 0.2)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFAEEA00)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      emoji,
                      style: TextStyle(
                        fontSize:
                            DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.022,
                            ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.black45),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading && controller.firstName.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFAEEA00)),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: DynamicSizeController.calculateWidthSize(context, 0.04),
            vertical: DynamicSizeController.calculateHeightSize(context, 0.03),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildProfileSection(context)),
              SizedBox(
                width: DynamicSizeController.calculateWidthSize(context, 0.04),
              ),
              Expanded(flex: 2, child: _buildQrSection(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DynamicSizeController.calculateAspectRatioSize(
              context,
              0.016,
            ),
            color: Colors.black87,
          ),
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.006),
        ),
        Text(
          'Edit your name and profile emoji. Email and role cannot be changed.',
          style: TextStyle(
            color: Colors.black45,
            fontSize: DynamicSizeController.calculateAspectRatioSize(
              context,
              0.011,
            ),
          ),
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.028),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _showEmojiPicker,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: DynamicSizeController.calculateAspectRatioSize(
                    context,
                    0.065,
                  ),
                  height: DynamicSizeController.calculateAspectRatioSize(
                    context,
                    0.065,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAEEA00).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFAEEA00),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmoji,
                      style: TextStyle(
                        fontSize:
                            DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.030,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: DynamicSizeController.calculateWidthSize(context, 0.016),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.displayName.isNotEmpty
                        ? controller.displayName
                        : 'Your Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: DynamicSizeController.calculateAspectRatioSize(
                        context,
                        0.016,
                      ),
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.email,
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: DynamicSizeController.calculateAspectRatioSize(
                        context,
                        0.011,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showEmojiPicker,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSmile,
                        color: Colors.black45,
                        size: DynamicSizeController.calculateAspectRatioSize(
                          context,
                          0.013,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Change Emoji',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize:
                              DynamicSizeController.calculateAspectRatioSize(
                                context,
                                0.011,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.028),
        ),
        const Divider(color: Color(0xFFE0E0E0)),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.022),
        ),
        _buildField(
          context,
          label: 'First Name',
          controller: _firstNameCtrl,
          icon: HugeIcons.strokeRoundedUser,
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.014),
        ),
        _buildField(
          context,
          label: 'Middle Name',
          controller: _middleNameCtrl,
          icon: HugeIcons.strokeRoundedUser,
          optional: true,
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.014),
        ),
        _buildField(
          context,
          label: 'Last Name',
          controller: _lastNameCtrl,
          icon: HugeIcons.strokeRoundedUser,
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.014),
        ),
        _buildReadOnlyField(
          context,
          label: 'Email Address',
          value: controller.email,
          icon: HugeIcons.strokeRoundedMail01,
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.014),
        ),
        _buildReadOnlyField(
          context,
          label: 'Role',
          value: controller.role.isNotEmpty
              ? controller.role[0].toUpperCase() + controller.role.substring(1)
              : 'Teacher',
          icon: HugeIcons.strokeRoundedTeacher,
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.028),
        ),
        GestureDetector(
          onTap: controller.isLoading
              ? null
              : () async {
                  await controller.saveProfile(
                    firstName: _firstNameCtrl.text,
                    middleName: _middleNameCtrl.text,
                    lastName: _lastNameCtrl.text,
                    emoji: _selectedEmoji,
                  );
                },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: DynamicSizeController.calculateHeightSize(
                  context,
                  0.016,
                ),
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: controller.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize:
                            DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.013,
                            ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My QR Code',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: DynamicSizeController.calculateAspectRatioSize(
              context,
              0.016,
            ),
            color: Colors.black87,
          ),
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.006),
        ),
        Text(
          'Use this QR code to verify sessions at the kiosk.',
          style: TextStyle(
            color: Colors.black45,
            fontSize: DynamicSizeController.calculateAspectRatioSize(
              context,
              0.011,
            ),
          ),
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.022),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            DynamicSizeController.calculateAspectRatioSize(context, 0.022),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                        size: DynamicSizeController.calculateAspectRatioSize(
                          context,
                          0.016,
                        ),
                      ),
                      SizedBox(
                        width: DynamicSizeController.calculateWidthSize(
                          context,
                          0.006,
                        ),
                      ),
                      Text(
                        controller.qrVisible ? 'QR Visible' : 'QR Hidden',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize:
                              DynamicSizeController.calculateAspectRatioSize(
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
                    onChanged: (_) => controller.toggleQrVisibility(),
                    activeThumbColor: const Color(0xFFAEEA00),
                    activeTrackColor: const Color(
                      0xFFAEEA00,
                    ).withValues(alpha: 0.3),
                  ),
                ],
              ),
              SizedBox(
                height: DynamicSizeController.calculateHeightSize(
                  context,
                  0.018,
                ),
              ),
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
                    child: controller.qrPayload.isEmpty
                        ? SizedBox(
                            width:
                                DynamicSizeController.calculateAspectRatioSize(
                                  context,
                                  0.18,
                                ),
                            height:
                                DynamicSizeController.calculateAspectRatioSize(
                                  context,
                                  0.18,
                                ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFAEEA00),
                              ),
                            ),
                          )
                        : QrImageView(
                            data: controller.qrPayload,
                            version: QrVersions.auto,
                            size:
                                DynamicSizeController.calculateAspectRatioSize(
                                  context,
                                  0.18,
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
                  width: DynamicSizeController.calculateAspectRatioSize(
                    context,
                    0.18,
                  ),
                  height: DynamicSizeController.calculateAspectRatioSize(
                    context,
                    0.18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedViewOff,
                          color: Colors.black26,
                          size: DynamicSizeController.calculateAspectRatioSize(
                            context,
                            0.035,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toggle to reveal',
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize:
                                DynamicSizeController.calculateAspectRatioSize(
                                  context,
                                  0.011,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: DynamicSizeController.calculateHeightSize(
                  context,
                  0.016,
                ),
              ),
              if (controller.qrVisible) ...[
                Text(
                  controller.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: DynamicSizeController.calculateAspectRatioSize(
                      context,
                      0.013,
                    ),
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Teacher',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: DynamicSizeController.calculateAspectRatioSize(
                      context,
                      0.010,
                    ),
                  ),
                ),
                SizedBox(
                  height: DynamicSizeController.calculateHeightSize(
                    context,
                    0.014,
                  ),
                ),
                GestureDetector(
                  onTap: _saveQrImage,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: DynamicSizeController.calculateHeightSize(
                          context,
                          0.012,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedDownload01,
                            color: Colors.black54,
                            size:
                                DynamicSizeController.calculateAspectRatioSize(
                                  context,
                                  0.015,
                                ),
                          ),
                          SizedBox(
                            width: DynamicSizeController.calculateWidthSize(
                              context,
                              0.006,
                            ),
                          ),
                          Text(
                            'Save QR Image',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontSize:
                                  DynamicSizeController.calculateAspectRatioSize(
                                    context,
                                    0.012,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: DynamicSizeController.calculateHeightSize(
                    context,
                    0.010,
                  ),
                ),
                GestureDetector(
                  onTap: controller.regenerating
                      ? null
                      : () => _showRegenerateDialog(context),
                  child: MouseRegion(
                    cursor: controller.regenerating
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: controller.regenerating ? 0.5 : 1.0,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: DynamicSizeController.calculateHeightSize(
                            context,
                            0.012,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFE53935,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            controller.regenerating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFE53935),
                                    ),
                                  )
                                : HugeIcon(
                                    icon: HugeIcons.strokeRoundedRefresh,
                                    color: const Color(0xFFE53935),
                                    size:
                                        DynamicSizeController.calculateAspectRatioSize(
                                          context,
                                          0.015,
                                        ),
                                  ),
                            SizedBox(
                              width: DynamicSizeController.calculateWidthSize(
                                context,
                                0.006,
                              ),
                            ),
                            Text(
                              controller.regenerating
                                  ? 'Regenerating...'
                                  : 'Regenerate QR Code',
                              style: TextStyle(
                                color: const Color(0xFFE53935),
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    DynamicSizeController.calculateAspectRatioSize(
                                      context,
                                      0.012,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: DynamicSizeController.calculateHeightSize(context, 0.016),
        ),
        Container(
          padding: EdgeInsets.all(
            DynamicSizeController.calculateAspectRatioSize(context, 0.014),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFCC80)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: const Color(0xFFE65100),
                size: DynamicSizeController.calculateAspectRatioSize(
                  context,
                  0.016,
                ),
              ),
              SizedBox(
                width: DynamicSizeController.calculateWidthSize(context, 0.008),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep your QR code private',
                      style: TextStyle(
                        color: const Color(0xFFE65100),
                        fontWeight: FontWeight.w700,
                        fontSize:
                            DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.012,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your QR code is the key to verifying class sessions. '
                      'Do not share it with students or anyone else. '
                      'Anyone with this code can verify sessions on your behalf.',
                      style: TextStyle(
                        color: const Color(0xFFBF360C),
                        fontSize:
                            DynamicSizeController.calculateAspectRatioSize(
                              context,
                              0.010,
                            ),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required List<List<dynamic>> icon,
    bool optional = false,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: DynamicSizeController.calculateAspectRatioSize(
          context,
          0.013,
        ),
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: optional ? '$label (optional)' : label,
        labelStyle: TextStyle(
          color: Colors.black45,
          fontSize: DynamicSizeController.calculateAspectRatioSize(
            context,
            0.012,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: HugeIcon(
            icon: icon,
            color: Colors.black38,
            size: DynamicSizeController.calculateAspectRatioSize(
              context,
              0.016,
            ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFAEEA00), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: DynamicSizeController.calculateWidthSize(context, 0.012),
          vertical: DynamicSizeController.calculateHeightSize(context, 0.014),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context, {
    required String label,
    required String value,
    required List<List<dynamic>> icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DynamicSizeController.calculateWidthSize(context, 0.012),
        vertical: DynamicSizeController.calculateHeightSize(context, 0.014),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            color: Colors.black26,
            size: DynamicSizeController.calculateAspectRatioSize(
              context,
              0.016,
            ),
          ),
          SizedBox(
            width: DynamicSizeController.calculateWidthSize(context, 0.010),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: DynamicSizeController.calculateAspectRatioSize(
                      context,
                      0.010,
                    ),
                  ),
                ),
                Text(
                  value,
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
          HugeIcon(
            icon: HugeIcons.strokeRoundedLocked,
            color: Colors.black26,
            size: DynamicSizeController.calculateAspectRatioSize(
              context,
              0.013,
            ),
          ),
        ],
      ),
    );
  }
}
