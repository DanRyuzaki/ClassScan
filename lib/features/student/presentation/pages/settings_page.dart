import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import '../../logic/profile_controller.dart';
import '../../../../core/controllers/dynamicsize_controller.dart';

class StudentSettingsPage extends StatefulWidget {
  const StudentSettingsPage({super.key});
  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  final StudentProfileController controller = StudentProfileController();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _lastNameCtrl;
  String _selectedEmoji = '🧑‍🎓';
  final List<String> _emojis = [
    '🧑‍🎓',
    '👩‍🎓',
    '👨‍🎓',
    '📚',
    '✏️',
    '📝',
    '🎒',
    '🏫',
    '💡',
    '🌟',
    '🎨',
    '🔬',
    '🧑‍💻',
    '👩‍💻',
    '👨‍💻',
    '🎭',
    '🏆',
    '😊',
  ];
  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController();
    _middleNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (controller.status == ProfileStatus.idle &&
        _firstNameCtrl.text.isEmpty &&
        controller.firstName.isNotEmpty) {
      _firstNameCtrl.text = controller.firstName;
      _middleNameCtrl.text = controller.middleName;
      _lastNameCtrl.text = controller.lastName;
      setState(() => _selectedEmoji = controller.emoji);
    }
    if (controller.status == ProfileStatus.success &&
        controller.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showToast(title: 'Saved', message: controller.successMessage!);
          controller.clearStatus();
        }
      });
    } else if (controller.status == ProfileStatus.error &&
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
    controller.removeListener(_onUpdate);
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

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Choose Profile Emoji',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
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
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
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
    final isSmall = MediaQuery.of(context).size.width < 700;
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
            horizontal: isSmall
                ? 20
                : DynamicSizeController.calculateWidthSize(context, 0.06),
            vertical: isSmall
                ? 24
                : DynamicSizeController.calculateHeightSize(context, 0.03),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showEmojiPicker,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFAEEA00,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFAEEA00),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _selectedEmoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.displayName.isNotEmpty
                                  ? controller.displayName
                                  : 'Your Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              controller.email,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
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
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedSmile,
                                  color: Colors.black45,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Divider(color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 22),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Email and role cannot be changed.',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    label: 'First Name',
                    ctrl: _firstNameCtrl,
                    icon: HugeIcons.strokeRoundedUser,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Middle Name (optional)',
                    ctrl: _middleNameCtrl,
                    icon: HugeIcons.strokeRoundedUser,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Last Name',
                    ctrl: _lastNameCtrl,
                    icon: HugeIcons.strokeRoundedUser,
                  ),
                  const SizedBox(height: 12),
                  _buildReadOnly(
                    label: 'Email Address',
                    value: controller.email,
                    icon: HugeIcons.strokeRoundedMail01,
                  ),
                  const SizedBox(height: 12),
                  _buildReadOnly(
                    label: 'Role',
                    value: 'Student',
                    icon: HugeIcons.strokeRoundedStudents,
                  ),
                  const SizedBox(height: 28),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
      },
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required List<List<dynamic>> icon,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: HugeIcon(icon: icon, color: Colors.black38, size: 18),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildReadOnly({
    required String label,
    required String value,
    required List<List<dynamic>> icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: Colors.black26, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
          HugeIcon(
            icon: HugeIcons.strokeRoundedLocked,
            color: Colors.black26,
            size: 14,
          ),
        ],
      ),
    );
  }
}
