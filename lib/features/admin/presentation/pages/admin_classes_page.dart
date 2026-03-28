import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import '../../logic/admin_classes_controller.dart';
import '../../../../../core/controllers/dynamicsize_controller.dart';

const _kBlue = Color(0xFF1565C0);

class AdminClassesPage extends StatefulWidget {
  const AdminClassesPage({super.key});
  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage> {
  final AdminClassesController _ctrl = AdminClassesController();
  final TextEditingController _searchCtrl = TextEditingController();
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
  void initState() {
    super.initState();
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
    final color = isError ? const Color(0xFFE53935) : _kBlue;
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

  void _showDeleteClassDialog(AdminClassModel cls) {
    final int mathA = 2 + (DateTime.now().millisecondsSinceEpoch % 18);
    final int mathB = 2 + (DateTime.now().microsecondsSinceEpoch % 8);
    final int mathAnswer = mathA + mathB;
    final mathCtrl = TextEditingController();
    bool deleting = false;
    String? mathError;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
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
            'Delete Class?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You are about to permanently delete\n'
                  '"${cls.subjectName}" (${cls.classCode}).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF57F17),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'All sessions and attendance records for this '
                          'class will also be permanently deleted.',
                          style: TextStyle(
                            color: Color(0xFF5D4037),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: const Text(
                    '⚠️  This action cannot be undone.',
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
            GestureDetector(
              onTap: deleting
                  ? null
                  : () async {
                      final typed = int.tryParse(mathCtrl.text.trim());
                      if (typed == null || typed != mathAnswer) {
                        setDS(
                          () =>
                              mathError = 'Incorrect answer. Please try again.',
                        );
                        return;
                      }
                      setDS(() => deleting = true);
                      final err = await _ctrl.deleteClass(cls.id);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (err != null) {
                        _toast(title: 'Error', message: err, isError: true);
                      } else {
                        _toast(
                          title: 'Class Deleted',
                          message:
                              '"${cls.subjectName}" and its sessions have been removed.',
                          isError: true,
                        );
                      }
                    },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: deleting ? 0.6 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: deleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Delete',
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

  void _showClassDetail(AdminClassModel cls) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSchoolReportCard,
              color: _kBlue,
              size: 22,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                cls.subjectName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cls.hasActiveSession)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF2E7D32), size: 8),
                      SizedBox(width: 8),
                      Text(
                        'Session currently running',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              _detailRow('Class Code', cls.classCode),
              _detailRow('School', cls.school.isNotEmpty ? cls.school : '—'),
              _detailRow(
                'Teacher',
                cls.teacherName.isNotEmpty ? cls.teacherName : '—',
              ),
              _detailRow('Enrolled Students', '${cls.enrolledCount}'),
              _detailRow('Pending Requests', '${cls.pendingCount}'),
              _detailRow(
                'Last Session',
                cls.lastSessionDate ?? 'No sessions yet',
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.black45)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteClassDialog(cls);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Delete Class',
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
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              const Expanded(child: _ClassesShimmer())
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
              Expanded(child: _searchField()),
              const SizedBox(width: 8),
              _refreshButton(),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchField(),
              const SizedBox(height: 10),
              Row(children: [const Spacer(), _refreshButton()]),
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
          hintText: 'Search by subject, code, teacher, or school…',
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
            borderSide: const BorderSide(color: _kBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _refreshButton() {
    return GestureDetector(
      onTap: _ctrl.loadClasses,
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
          child: const Icon(
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
              icon: HugeIcons.strokeRoundedSchoolReportCard,
              color: Colors.black12,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No results for "${_searchCtrl.text}"'
                  : 'No classes found.',
              style: const TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isWide)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(width: _w(0.025, min: 16)),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'SUBJECT',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'TEACHER',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'MEMBERS',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 110,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _ClassRow(
              cls: items[i],
              isWide: _isWide,
              onTap: () => _showClassDetail(items[i]),
              onDelete: () => _showDeleteClassDialog(items[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${items.length} ${items.length == 1 ? 'class' : 'classes'}'
            '${_searchCtrl.text.isNotEmpty ? ' found' : ' total'}',
            style: const TextStyle(color: Colors.black38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  final AdminClassModel cls;
  final bool isWide;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ClassRow({
    required this.cls,
    required this.isWide,
    required this.onTap,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cls.hasActiveSession
                ? const Color(0xFFF1F8E9)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cls.hasActiveSession
                  ? const Color(0xFFA5D6A7)
                  : const Color(0xFFEEEEEE),
            ),
          ),
          child: isWide ? _wideLayout() : _narrowLayout(),
        ),
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cls.subjectName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                cls.classCode,
                style: const TextStyle(color: Colors.black38, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            cls.teacherName.isNotEmpty ? cls.teacherName : '—',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 80,
          child: Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                color: Colors.black38,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${cls.enrolledCount}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (cls.pendingCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${cls.pendingCount}',
                    style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 110, child: _sessionBadge()),
        GestureDetector(
          onTap: onDelete,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE53935),
                    size: 13,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.subjectName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    cls.classCode,
                    style: const TextStyle(color: Colors.black38, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _sessionBadge(),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              color: Colors.black38,
              size: 13,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                cls.teacherName.isNotEmpty ? cls.teacherName : 'No teacher',
                style: const TextStyle(color: Colors.black45, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.people_outline_rounded,
              color: Colors.black38,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              '${cls.enrolledCount} enrolled',
              style: const TextStyle(color: Colors.black45, fontSize: 11),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onDelete,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE53935),
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sessionBadge() {
    if (cls.hasActiveSession) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'Live',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    if (cls.lastSessionDate != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          cls.lastSessionDate!,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Text(
        'No sessions',
        style: TextStyle(
          color: Colors.black38,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ClassesShimmer extends StatelessWidget {
  const _ClassesShimmer();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ShimmerBox(width: double.infinity, height: 44, borderRadius: 10),
        const SizedBox(height: 14),
        ...List.generate(
          8,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ShimmerBox(
              width: double.infinity,
              height: 62,
              borderRadius: 10,
            ),
          ),
        ),
      ],
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
