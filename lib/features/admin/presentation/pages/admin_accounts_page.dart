import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import '../../logic/admin_accounts_controller.dart';
import '../../../../../core/controllers/dynamicsize_controller.dart';

const _kAdminBlue = Color(0xFF1565C0);

class AdminAccountsPage extends StatefulWidget {
  final String role;
  const AdminAccountsPage({super.key, required this.role});
  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  late final AdminAccountsController _ctrl;
  final TextEditingController _searchCtrl = TextEditingController();
  double _fs(double pct, {double min = 11, double max = 22}) =>
      DynamicSizeController.calculateAspectRatioSize(
        context,
        pct,
      ).clamp(min, max);
  double _w(double pct, {double min = 8, double max = 2000}) =>
      DynamicSizeController.calculateWidthSize(context, pct).clamp(min, max);
  double _h(double pct, {double min = 4, double max = 2000}) =>
      DynamicSizeController.calculateHeightSize(context, pct).clamp(min, max);
  bool get _isWide => MediaQuery.of(context).size.width >= 700;
  @override
  void initState() {
    super.initState();
    _ctrl = AdminAccountsController(role: widget.role);
    _searchCtrl.addListener(() => _ctrl.updateSearch(_searchCtrl.text));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toast({
    required String title,
    required String message,
    bool isError = false,
  }) {
    final color = isError ? const Color(0xFFE53935) : _kAdminBlue;
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

  void _showCreateDialog() {
    final firstCtrl = TextEditingController();
    final middleCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? errorMsg;
    bool saving = false;
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
              HugeIcon(
                icon: HugeIcons.strokeRoundedUserAdd01,
                color: _kAdminBlue,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Create ${widget.role == 'student' ? 'Student' : 'Teacher'} Account',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMsg!,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _dialogField(
                  ctrl: firstCtrl,
                  label: 'First Name',
                  required: true,
                ),
                const SizedBox(height: 10),
                _dialogField(ctrl: middleCtrl, label: 'Middle Name'),
                const SizedBox(height: 10),
                _dialogField(
                  ctrl: lastCtrl,
                  label: 'Last Name',
                  required: true,
                ),
                const SizedBox(height: 10),
                _dialogField(
                  ctrl: emailCtrl,
                  label: 'Google Email',
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFF57F17),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The account will activate when this person '
                          'first signs in with their Google account.',
                          style: const TextStyle(
                            color: Color(0xFF5D4037),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black45),
              ),
            ),
            _actionButton(
              label: 'Create',
              loading: saving,
              onTap: () async {
                setDS(() {
                  errorMsg = null;
                  saving = true;
                });
                final err = await _ctrl.createAccount(
                  firstName: firstCtrl.text,
                  middleName: middleCtrl.text,
                  lastName: lastCtrl.text,
                  email: emailCtrl.text,
                );
                if (!ctx.mounted) return;
                if (err != null) {
                  setDS(() {
                    errorMsg = err;
                    saving = false;
                  });
                } else {
                  Navigator.of(ctx).pop();
                  _toast(
                    title: 'Account Created',
                    message:
                        '${firstCtrl.text.trim()} ${lastCtrl.text.trim()} has been added.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(AdminAccountModel account) {
    final isTeacher = widget.role == 'teacher';
    final int mathA = 2 + (DateTime.now().millisecondsSinceEpoch % 18);
    final int mathB = 2 + (DateTime.now().microsecondsSinceEpoch % 8);
    final int mathAnswer = mathA + mathB;
    final mathCtrl = TextEditingController();
    bool deleting = false;
    String? mathError;
    int? teacherClassCount;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) {
          if (isTeacher && teacherClassCount == null) {
            _ctrl.getTeacherClassCount(account.uid).then((count) {
              if (ctx.mounted) setDS(() => teacherClassCount = count);
            });
          }
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.delete_forever_rounded,
              color: Color(0xFFE53935),
              size: 32,
            ),
            title: const Text(
              'Delete Account?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You are about to permanently delete the account for\n'
                    '"${account.displayName}" (${account.email}).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  if (isTeacher) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: teacherClassCount == null
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFF57F17),
                                ),
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFF57F17),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    teacherClassCount == 0
                                        ? 'This teacher has no classes. Only their '
                                              'account and login access will be removed.'
                                        : 'This teacher owns $teacherClassCount '
                                              '${teacherClassCount == 1 ? 'class' : 'classes'}. '
                                              'Deleting this account will also permanently '
                                              'delete all of their classes and class data.',
                                    style: const TextStyle(
                                      color: Color(0xFF5D4037),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: const Text(
                      '⚠️  This action cannot be undone. The account and '
                      'login access will be permanently removed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB71C1C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'To confirm, solve: $mathA + $mathB = ?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: mathCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    onChanged: (_) {
                      if (mathError != null) setDS(() => mathError = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter the answer…',
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                      errorText: mathError,
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
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
              _actionButton(
                label: 'Delete',
                loading: deleting,
                isDestructive: true,
                onTap: () async {
                  final typed = int.tryParse(mathCtrl.text.trim());
                  if (typed == null || typed != mathAnswer) {
                    setDS(
                      () => mathError = 'Incorrect answer. Please try again.',
                    );
                    return;
                  }
                  setDS(() => deleting = true);
                  final err = await _ctrl.deleteAccount(account.uid);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (err != null) {
                    _toast(title: 'Error', message: err, isError: true);
                  } else {
                    _toast(
                      title: 'Account Deleted',
                      message: isTeacher
                          ? '${account.displayName} and their classes have been removed.'
                          : '${account.displayName} has been removed.',
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBanDialog(AdminAccountModel account) {
    final reasonCtrl = TextEditingController();
    int days = 3;
    String? errorMsg;
    bool saving = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.block_rounded,
                color: Color(0xFFE53935),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Suspend ${account.displayName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                if (errorMsg != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMsg!,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Duration (days)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 3, 7, 14, 30].map((d) {
                    final selected = days == d;
                    return GestureDetector(
                      onTap: () => setDS(() => days = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE53935)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFE53935)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          '$d ${d == 1 ? 'day' : 'days'}',
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Reason',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Explain why this account is being suspended…',
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontSize: 12,
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
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black45),
              ),
            ),
            _actionButton(
              label: 'Suspend',
              loading: saving,
              isDestructive: true,
              onTap: () async {
                if (reasonCtrl.text.trim().isEmpty) {
                  setDS(() => errorMsg = 'Please provide a reason.');
                  return;
                }
                setDS(() {
                  errorMsg = null;
                  saving = true;
                });
                final err = await _ctrl.banAccount(
                  uid: account.uid,
                  days: days,
                  reason: reasonCtrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (err != null) {
                  _toast(title: 'Error', message: err, isError: true);
                } else {
                  _toast(
                    title: 'Account Suspended',
                    message:
                        '${account.displayName} suspended for $days ${days == 1 ? 'day' : 'days'}.',
                    isError: true,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUnbanDialog(AdminAccountModel account) {
    bool saving = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.lock_open_rounded,
            color: Color(0xFF1565C0),
            size: 32,
          ),
          title: const Text(
            'Lift Suspension?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Remove the suspension on "${account.displayName}"?\n\n'
            'They will be able to sign in immediately.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black45),
              ),
            ),
            _actionButton(
              label: 'Lift Suspension',
              loading: saving,
              onTap: () async {
                setDS(() => saving = true);
                final err = await _ctrl.unbanAccount(account.uid);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (err != null) {
                  _toast(title: 'Error', message: err, isError: true);
                } else {
                  _toast(
                    title: 'Suspension Lifted',
                    message: '${account.displayName} can now sign in.',
                  );
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
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.all(_isWide ? _w(0.025) : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToolbar(),
              SizedBox(height: _h(0.02, min: 14)),
              if (_ctrl.isLoading)
                const Expanded(child: _AccountsShimmer())
              else
                Expanded(child: _buildList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar() {
    return _isWide
        ? Row(
            children: [
              Expanded(child: _searchField()),
              const SizedBox(width: 12),
              _createButton(),
              const SizedBox(width: 8),
              _refreshButton(),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchField(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _createButton()),
                  const SizedBox(width: 8),
                  _refreshButton(),
                ],
              ),
            ],
          );
  }

  Widget _searchField() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(fontSize: _fs(0.013, min: 12, max: 14)),
        decoration: InputDecoration(
          hintText:
              'Search ${widget.role == 'student' ? 'students' : 'teachers'}…',
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.black38,
            size: 18,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.black38,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    _ctrl.updateSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAdminBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _createButton() {
    return GestureDetector(
      onTap: _showCreateDialog,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: _kAdminBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                'New ${widget.role == 'student' ? 'Student' : 'Teacher'}',
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
      onTap: _ctrl.isSaving ? null : _ctrl.loadAccounts,
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
                      color: _kAdminBlue,
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
    final items = _ctrl.filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: widget.role == 'student'
                  ? HugeIcons.strokeRoundedStudents
                  : HugeIcons.strokeRoundedTeacher,
              color: Colors.black12,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No results for "${_searchCtrl.text}"'
                  : 'No ${widget.role} accounts yet.',
              style: const TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isWide) _buildHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _AccountRow(
              account: items[i],
              isWide: _isWide,
              onDelete: () => _showDeleteDialog(items[i]),
              onBan: () => _showBanDialog(items[i]),
              onUnban: () => _showUnbanDialog(items[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${items.length} ${items.length == 1 ? 'account' : 'accounts'}${_searchCtrl.text.isNotEmpty ? ' found' : ' total'}',
            style: const TextStyle(color: Colors.black38, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
      child: Row(
        children: [
          const SizedBox(width: 36 + 12),
          const Expanded(flex: 3, child: _HeaderLabel('NAME')),
          const Expanded(flex: 3, child: _HeaderLabel('EMAIL')),
          const SizedBox(width: 120, child: _HeaderLabel('LAST SESSION')),
          const SizedBox(width: 100, child: _HeaderLabel('STATUS')),
          const SizedBox(width: _AccountRow.actionsWidth),
        ],
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController ctrl,
    required String label,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 13),
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
          borderSide: const BorderSide(color: _kAdminBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onTap,
    bool loading = false,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFE53935) : _kAdminBlue;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: loading ? 0.6 : 1.0,
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

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black38,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AdminAccountModel account;
  final bool isWide;
  final VoidCallback onDelete;
  final VoidCallback onBan;
  final VoidCallback onUnban;
  static const double actionsWidth = 160.0;
  const _AccountRow({
    required this.account,
    required this.isWide,
    required this.onDelete,
    required this.onBan,
    required this.onUnban,
  });
  @override
  Widget build(BuildContext context) {
    final banned = account.isCurrentlyBanned;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: banned ? const Color(0xFFFFF3F3) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: banned ? const Color(0xFFFFCDD2) : const Color(0xFFEEEEEE),
        ),
      ),
      child: isWide ? _wideLayout(banned) : _narrowLayout(banned),
    );
  }

  Widget _wideLayout(bool banned) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: banned ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(account.emoji, style: const TextStyle(fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (banned && account.banReason != null)
                Text(
                  'Reason: ${account.banReason}',
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            account.email,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 120, child: _lastSessionChip(account.lastSessionLabel)),
        SizedBox(
          width: 100,
          child: banned ? _banBadge(account.daysRemainingBan) : _activeBadge(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: _actionButtons(banned),
        ),
      ],
    );
  }

  Widget _narrowLayout(bool banned) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: banned
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  account.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    account.email,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            banned ? _banBadge(account.daysRemainingBan) : _activeBadge(),
          ],
        ),
        if (banned && account.banReason != null) ...[
          const SizedBox(height: 6),
          Text(
            'Reason: ${account.banReason}',
            style: const TextStyle(color: Color(0xFFE53935), fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 12,
              color: Colors.black38,
            ),
            const SizedBox(width: 4),
            Text(
              account.lastSessionLabel,
              style: const TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: _actionButtons(banned),
        ),
      ],
    );
  }

  List<Widget> _actionButtons(bool banned) {
    return [
      if (banned)
        _rowButton(
          icon: Icons.lock_open_rounded,
          label: 'Unban',
          color: const Color(0xFF1565C0),
          onTap: onUnban,
        )
      else
        _rowButton(
          icon: Icons.block_rounded,
          label: 'Suspend',
          color: const Color(0xFFF57F17),
          onTap: onBan,
        ),
      const SizedBox(width: 6),
      _rowButton(
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        color: const Color(0xFFE53935),
        onTap: onDelete,
      ),
    ];
  }

  Widget _rowButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
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

  Widget _lastSessionChip(String label) {
    final isToday = label == 'Today';
    final isNever = label == 'Never';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNever
            ? const Color(0xFFF5F5F5)
            : isToday
            ? const Color(0xFFE3F2FD)
            : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isNever
              ? const Color(0xFFE0E0E0)
              : isToday
              ? const Color(0xFF90CAF9)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isNever
              ? Colors.black38
              : isToday
              ? const Color(0xFF1565C0)
              : Colors.black54,
          fontSize: 11,
          fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: const Text(
        'Active',
        style: TextStyle(
          color: Color(0xFF2E7D32),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _banBadge(int daysLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Text(
        '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
        style: const TextStyle(
          color: Color(0xFFE53935),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AccountsShimmer extends StatelessWidget {
  const _AccountsShimmer();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _shimmer(double.infinity, 44, radius: 10),
        const SizedBox(height: 14),
        ...List.generate(
          8,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _shimmer(double.infinity, 62, radius: 10),
          ),
        ),
      ],
    );
  }

  Widget _shimmer(double w, double h, {double radius = 8}) {
    return _ShimmerBox(width: w, height: h, borderRadius: radius);
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
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
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
