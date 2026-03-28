import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import '../../logic/admin_controller.dart';
import '../../logic/admin_admins_controller.dart';
import '../../../../../core/controllers/dynamicsize_controller.dart';

const _kBlue = Color(0xFF1565C0);
const _kRed = Color(0xFFE53935);

class AdminSettingsPage extends StatefulWidget {
  final AdminController adminController;
  const AdminSettingsPage({super.key, required this.adminController});
  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  AdminController get _ctrl => widget.adminController;
  final AdminAdminsController _adminsCtrl = AdminAdminsController();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _lastNameCtrl;
  String _selectedEmoji = '🛡️';
  static const double _mobileBreak = 700;
  final List<String> _emojis = [
    '🛡️',
    '🔐',
    '⚙️',
    '🧑‍💻',
    '👩‍💻',
    '👨‍💻',
    '🧑‍🏫',
    '👩‍🏫',
    '👨‍🏫',
    '🎓',
    '📚',
    '💡',
    '🌟',
    '🏫',
    '📝',
    '🔬',
    '🧪',
    '📐',
  ];
  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: _ctrl.firstName);
    _middleNameCtrl = TextEditingController(text: _ctrl.middleName);
    _lastNameCtrl = TextEditingController(text: _ctrl.lastName);
    _selectedEmoji = _ctrl.emoji.isNotEmpty ? _ctrl.emoji : '🛡️';
    _ctrl.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (_ctrl.status == AdminStatus.idle && _ctrl.firstName.isNotEmpty) {
      if (_firstNameCtrl.text.isEmpty) {
        _firstNameCtrl.text = _ctrl.firstName;
        _middleNameCtrl.text = _ctrl.middleName;
        _lastNameCtrl.text = _ctrl.lastName;
        setState(() => _selectedEmoji = _ctrl.emoji);
      }
    }
    if (_ctrl.status == AdminStatus.success && _ctrl.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _toast(title: 'Saved', message: _ctrl.successMessage!);
          _ctrl.clearStatus();
        }
      });
    } else if (_ctrl.status == AdminStatus.error &&
        _ctrl.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _toast(title: 'Error', message: _ctrl.errorMessage!, isError: true);
          _ctrl.clearStatus();
        }
      });
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _adminsCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _toast({
    required String title,
    required String message,
    bool isError = false,
  }) {
    final color = isError ? _kRed : _kBlue;
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
                          ? _kBlue.withValues(alpha: 0.12)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _kBlue : Colors.transparent,
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

  void _showRemoveSelfDialog() {
    if (_adminsCtrl.isOnlyAdmin) {
      _toast(
        title: 'Cannot Remove',
        message: 'You are the only admin. Promote another admin first.',
        isError: true,
      );
      return;
    }
    bool removing = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.shield_outlined, color: _kRed, size: 36),
          title: const Text(
            'Remove Admin Role?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You will be downgraded back to a teacher account and signed out immediately.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: _kRed, size: 15),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This cannot be undone without another admin restoring your role.',
                        style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: removing ? null : () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black45),
              ),
            ),
            GestureDetector(
              onTap: removing
                  ? null
                  : () async {
                      setDS(() => removing = true);
                      final err = await _adminsCtrl.removeSelfAdmin();
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (err != null) {
                        _toast(title: 'Error', message: err, isError: true);
                      } else {
                        await _ctrl.signOut();
                      }
                    },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: removing ? 0.6 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: removing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Remove & Sign Out',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        if (_ctrl.isLoading && _ctrl.firstName.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _kBlue));
        }
        final isMobile = MediaQuery.of(context).size.width < _mobileBreak;
        return isMobile ? _buildMobile() : _buildDesktop();
      },
    );
  }

  Widget _buildDesktop() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: DynamicSizeController.calculateWidthSize(context, 0.04),
        vertical: DynamicSizeController.calculateHeightSize(context, 0.03),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: _buildProfileSection(),
      ),
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: _buildProfileSection(),
    );
  }

  Widget _buildProfileSection() {
    final isMobile = MediaQuery.of(context).size.width < _mobileBreak;
    final titleFs = isMobile
        ? 15.0
        : DynamicSizeController.calculateAspectRatioSize(context, 0.016);
    final subtitleFs = isMobile
        ? 12.0
        : DynamicSizeController.calculateAspectRatioSize(context, 0.011);
    final avatarSize = isMobile
        ? 60.0
        : DynamicSizeController.calculateAspectRatioSize(context, 0.065);
    final avatarEmojiSize = isMobile
        ? 28.0
        : DynamicSizeController.calculateAspectRatioSize(context, 0.030);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFs,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Edit your name and profile emoji. Email cannot be changed.',
          style: TextStyle(color: Colors.black45, fontSize: subtitleFs),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            GestureDetector(
              onTap: _showEmojiPicker,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBlue, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmoji,
                      style: TextStyle(fontSize: avatarEmojiSize),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ctrl.displayName.isNotEmpty
                        ? _ctrl.displayName
                        : 'Your Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: titleFs,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ctrl.email,
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: subtitleFs,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Change Emoji',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFE0E0E0)),
        const SizedBox(height: 16),
        _buildField(
          label: 'First Name',
          ctrl: _firstNameCtrl,
          icon: HugeIcons.strokeRoundedUser,
        ),
        const SizedBox(height: 12),
        _buildField(
          label: 'Middle Name',
          ctrl: _middleNameCtrl,
          icon: HugeIcons.strokeRoundedUser,
          optional: true,
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
          value: _ctrl.email,
          icon: HugeIcons.strokeRoundedMail01,
        ),
        const SizedBox(height: 12),
        _buildReadOnly(
          label: 'Role',
          value: 'Admin',
          icon: HugeIcons.strokeRoundedShieldUser,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _ctrl.isLoading
              ? null
              : () async {
                  await _ctrl.saveProfile(
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
                gradient: LinearGradient(
                  colors: [_kBlue, const Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: _ctrl.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Divider(color: Color(0xFFE0E0E0)),
        const SizedBox(height: 24),
        Text(
          'Danger Zone',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFs,
            color: _kRed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Removing your admin role will sign you out immediately '
          'and downgrade your account to teacher.',
          style: TextStyle(color: Colors.black45, fontSize: subtitleFs),
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: _adminsCtrl,
          builder: (_, _) {
            final isOnly = _adminsCtrl.isOnlyAdmin;
            return GestureDetector(
              onTap: isOnly ? null : _showRemoveSelfDialog,
              child: MouseRegion(
                cursor: isOnly
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isOnly ? 0.4 : 1.0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: _kRed,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOnly
                              ? 'Cannot Remove — You Are the Only Admin'
                              : 'Remove My Admin Role',
                          style: const TextStyle(
                            color: _kRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required List<List<dynamic>> icon,
    bool optional = false,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: optional ? '$label (optional)' : label,
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
          borderSide: const BorderSide(color: _kBlue, width: 2),
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
