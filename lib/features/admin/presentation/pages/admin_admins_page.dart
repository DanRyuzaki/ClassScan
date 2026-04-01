import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import '../../logic/admin_admins_controller.dart';
import '../../logic/admin_controller.dart';
import '../../../../../core/controllers/dynamicsize_controller.dart';

const _kBlue = Color(0xFF1565C0);
const _kRed = Color(0xFFE53935);

class AdminAdminsPage extends StatefulWidget {
  final AdminController adminController;
  const AdminAdminsPage({super.key, required this.adminController});
  @override
  State<AdminAdminsPage> createState() => _AdminAdminsPageState();
}

class _AdminAdminsPageState extends State<AdminAdminsPage> {
  final AdminAdminsController _ctrl = AdminAdminsController();
  double _fs(double p, {double min = 11, double max = 22}) =>
      DynamicSizeController.calculateAspectRatioSize(
        context,
        p,
      ).clamp(min, max);
  double _w(double p, {double min = 8, double max = 2000}) =>
      DynamicSizeController.calculateWidthSize(context, p).clamp(min, max);
  double _h(double p, {double min = 4, double max = 2000}) =>
      DynamicSizeController.calculateHeightSize(context, p).clamp(min, max);
  bool get _isWide => MediaQuery.of(context).size.width >= 700;
  @override
  void dispose() {
    _ctrl.dispose();
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
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.bottomRight,
      borderRadius: BorderRadius.circular(10),
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(color: color),
    );
  }

  void _showPromoteDialog() {
    final searchCtrl = TextEditingController();
    AdminUserModel? selected;
    bool searching = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) {
          Future<void> runSearch(String q) async {
            setDS(() => searching = true);
            await _ctrl.searchTeachers(q);
            if (ctx.mounted) setDS(() => searching = false);
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedShieldUser,
                  color: _kBlue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Add Admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFF57F17),
                          size: 14,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only existing teacher accounts can become admins. '
                            'Once promoted, they lose all teacher features.',
                            style: TextStyle(
                              color: Color(0xFF5D4037),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 44,
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (v) {
                        setDS(() => selected = null);
                        runSearch(v);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search teacher by name or email…',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.black38,
                          size: 18,
                        ),
                        suffixIcon: searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _kBlue,
                                  ),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: _kBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _ctrl,
                    builder: (_, _) {
                      final results = _ctrl.teacherResults;
                      if (searchCtrl.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      if (results.isEmpty && !searching) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'No teachers found.',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      if (results.isEmpty) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 6),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final t = results[i];
                            final isSelected = selected?.uid == t.uid;
                            return InkWell(
                              onTap: () => setDS(() => selected = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                color: isSelected
                                    ? _kBlue.withValues(alpha: 0.06)
                                    : null,
                                child: Row(
                                  children: [
                                    Text(
                                      t.emoji,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            t.email,
                                            style: const TextStyle(
                                              color: Colors.black45,
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: _kBlue,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                onPressed: () {
                  _ctrl.clearTeacherResults();
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
              _actionBtn(
                label: 'Next',
                onTap: selected == null
                    ? null
                    : () {
                        final sel = selected!;
                        _ctrl.clearTeacherResults();
                        Navigator.of(ctx).pop();
                        _showMathConfirmDialog(sel);
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMathConfirmDialog(AdminUserModel teacher) {
    final rng = Random();
    final a = rng.nextInt(9) + 1;
    final b = rng.nextInt(9) + 1;
    final correct = a + b;
    final answerCtrl = TextEditingController();
    String? errorMsg;
    bool promoting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.calculate_rounded, color: _kBlue, size: 22),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Confirm Promotion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBlue.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Text(teacher.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              teacher.email,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Teacher → Admin',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          'This teacher will lose access to all teacher features '
                          'and classes. This cannot be undone without admin action.',
                          style: TextStyle(
                            color: Color(0xFFB71C1C),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'To confirm, solve:  $a + $b = ?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: answerCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Your answer…',
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontSize: 13,
                    ),
                    errorText: errorMsg,
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
                      borderSide: const BorderSide(color: _kBlue, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: promoting ? null : () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black45),
              ),
            ),
            _actionBtn(
              label: 'Promote to Admin',
              loading: promoting,
              onTap: () async {
                final entered = int.tryParse(answerCtrl.text.trim());
                if (entered == null || entered != correct) {
                  setDS(() => errorMsg = 'Incorrect answer. Try again.');
                  return;
                }
                setDS(() {
                  errorMsg = null;
                  promoting = true;
                });
                final err = await _ctrl.promoteToAdmin(teacher.uid);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (err != null) {
                  _toast(title: 'Error', message: err, isError: true);
                } else {
                  _toast(
                    title: 'Promoted',
                    message: '${teacher.displayName} is now an admin.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveSelfDialog() {
    if (_ctrl.isOnlyAdmin) {
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
            _actionBtn(
              label: 'Remove & Sign Out',
              loading: removing,
              isDestructive: true,
              onTap: () async {
                setDS(() => removing = true);
                final err = await _ctrl.removeSelfAdmin();
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (err != null) {
                  _toast(title: 'Error', message: err, isError: true);
                } else {
                  await widget.adminController.signOut();
                }
              },
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
      builder: (context, _) => Padding(
        padding: EdgeInsets.all(_isWide ? _w(0.025) : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(),
            SizedBox(height: _h(0.02, min: 14)),
            if (_ctrl.isLoading)
              const Expanded(child: _AdminsShimmer())
            else
              Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return _isWide
        ? Row(
            children: [
              Text(
                '${_ctrl.admins.length} admin${_ctrl.admins.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: _fs(0.013, min: 12, max: 14),
                ),
              ),
              const Spacer(),
              _addAdminButton(),
              const SizedBox(width: 8),
              _refreshButton(),
            ],
          )
        : Row(
            children: [
              Expanded(child: _addAdminButton()),
              const SizedBox(width: 8),
              _refreshButton(),
            ],
          );
  }

  Widget _addAdminButton() {
    return GestureDetector(
      onTap: _showPromoteDialog,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'Add Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: _fs(0.012, min: 12, max: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _refreshButton() {
    return GestureDetector(
      onTap: _ctrl.isSaving ? null : _ctrl.loadAdmins,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: _ctrl.isSaving
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kBlue,
                    ),
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  color: Colors.black45,
                  size: 18,
                ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final admins = _ctrl.admins;
    if (admins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedShieldUser,
              color: Colors.black12,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'No admins found.',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isWide)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(width: 48),
                Expanded(
                  flex: 3,
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'EMAIL',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(width: 180),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: admins.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _AdminRow(
              admin: admins[i],
              isWide: _isWide,
              onRemoveSelf: _showRemoveSelfDialog,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${admins.length} admin${admins.length == 1 ? '' : 's'} total',
            style: const TextStyle(color: Colors.black38, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    VoidCallback? onTap,
    bool loading = false,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? _kRed : _kBlue;
    final disabled = onTap == null;
    return GestureDetector(
      onTap: (loading || disabled) ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: (loading || disabled) ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
        ),
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  final AdminUserModel admin;
  final bool isWide;
  final VoidCallback onRemoveSelf;
  const _AdminRow({
    required this.admin,
    required this.isWide,
    required this.onRemoveSelf,
  });
  @override
  Widget build(BuildContext context) {
    final isSelf = admin.isSelf;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelf ? const Color(0xFFE3F2FD) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelf ? const Color(0xFF90CAF9) : const Color(0xFFEEEEEE),
        ),
      ),
      child: isWide ? _wideLayout(isSelf) : _narrowLayout(isSelf),
    );
  }

  Widget _avatar(bool isSelf) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: isSelf
          ? const Color(0xFF1565C0).withValues(alpha: 0.15)
          : const Color(0xFFE3F2FD),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(admin.emoji, style: const TextStyle(fontSize: 18)),
    ),
  );
  Widget _youBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFF1565C0),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'You',
      style: TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  Widget _wideLayout(bool isSelf) {
    return Row(
      children: [
        _avatar(isSelf),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  admin.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelf) ...[const SizedBox(width: 8), _youBadge()],
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            admin.email,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 180,
          child: isSelf
              ? Align(alignment: Alignment.centerRight, child: _removeButton())
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _narrowLayout(bool isSelf) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(isSelf),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          admin.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf) ...[const SizedBox(width: 6), _youBadge()],
                    ],
                  ),
                  Text(
                    admin.email,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isSelf) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_removeButton()],
          ),
        ],
      ],
    );
  }

  Widget _removeButton() {
    return GestureDetector(
      onTap: onRemoveSelf,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kRed.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, color: _kRed, size: 13),
              const SizedBox(width: 4),
              const Text(
                'Remove My Admin Role',
                style: TextStyle(
                  color: _kRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminsShimmer extends StatelessWidget {
  const _AdminsShimmer();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ShimmerBox(
            width: double.infinity,
            height: 62,
            borderRadius: 10,
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width, height, borderRadius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFFE8E8E8),
              Color(0xFFF5F5F5),
              Color(0xFFEEEEEE),
              Color(0xFFF5F5F5),
              Color(0xFFE8E8E8),
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
      ),
    );
  }
}
