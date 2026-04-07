import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import '../../logic/classes_controller.dart';
import '../widgets/shimmer_widgets.dart';
import '../../../../core/controllers/dynamicsize_controller.dart';
class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});
  @override
  State<ClassesPage> createState() => _ClassesPageState();
}
class _ClassesPageState extends State<ClassesPage> {
  final ClassesController controller = ClassesController();
  final TextEditingController _searchCtrl = TextEditingController();
  double _fs(
    BuildContext context,
    double pct, {
    double min = 11,
    double max = 22,
  }) => DynamicSizeController.calculateAspectRatioSize(
    context,
    pct,
  ).clamp(min, max);
  double _w(
    BuildContext context,
    double pct, {
    double min = 8,
    double max = 2000,
  }) => DynamicSizeController.calculateWidthSize(context, pct).clamp(min, max);
  double _h(
    BuildContext context,
    double pct, {
    double min = 4,
    double max = 2000,
  }) => DynamicSizeController.calculateHeightSize(context, pct).clamp(min, max);
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => controller.updateSearch(_searchCtrl.text));
  }
  @override
  void dispose() {
    controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
  void _toast({
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
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.bottomRight,
      borderRadius: BorderRadius.circular(10),
      showProgressBar: true,
      progressBarTheme: ProgressIndicatorThemeData(color: color),
    );
  }
  void _showClassDialog({ClassModel? existing}) {
    final schoolCtrl = TextEditingController(text: existing?.school ?? '');
    final codeCtrl = TextEditingController(text: existing?.classCode ?? '');
    final subjectCtrl = TextEditingController(
      text: existing?.subjectName ?? '',
    );
    bool domainRestrictionEnabled = false;
    final List<String> allowedDomains = [];
    final domainInputCtrl = TextEditingController();
    String? domainInputError;
    String? errorMsg;
    bool isSaving = false;
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
              HugeIcon(
                icon: existing == null
                    ? HugeIcons.strokeRoundedAdd01
                    : HugeIcons.strokeRoundedEdit01,
                color: const Color(0xFFAEEA00),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                existing == null ? 'Create Class' : 'Edit Class',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
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
                        color: Color(0xFFB71C1C),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _dialogField(
                  ctrl: schoolCtrl,
                  label: 'School / Institution',
                  icon: HugeIcons.strokeRoundedBuilding01,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  ctrl: codeCtrl,
                  label: 'Class Code',
                  icon: HugeIcons.strokeRoundedCode,
                  hint: 'e.g. STEM12-A',
                  enabled: existing == null,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  ctrl: subjectCtrl,
                  label: 'Subject Name',
                  icon: HugeIcons.strokeRoundedBook01,
                ),
                if (existing == null) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  _DomainRestrictionSection(
                    enabled: domainRestrictionEnabled,
                    domains: allowedDomains,
                    inputCtrl: domainInputCtrl,
                    inputError: domainInputError,
                    onToggle: (v) => setDS(() {
                      domainRestrictionEnabled = v;
                      if (!v) allowedDomains.clear();
                      domainInputError = null;
                    }),
                    onAddDomain: () {
                      final raw = domainInputCtrl.text;
                      final err = ClassesController.validateEmailDomain(raw);
                      if (err != null) {
                        setDS(() => domainInputError = err);
                        return;
                      }
                      final normalized = raw.trim().toLowerCase();
                      if (allowedDomains.contains(normalized)) {
                        setDS(() => domainInputError = 'Domain already added.');
                        return;
                      }
                      setDS(() {
                        allowedDomains.add(normalized);
                        domainInputCtrl.clear();
                        domainInputError = null;
                      });
                    },
                    onRemoveDomain: (d) =>
                        setDS(() => allowedDomains.remove(d)),
                    isCreating: true,
                  ),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
              child: const Text('Cancel'),
            ),
            _gradientButton(
              label: existing == null ? 'Create' : 'Save',
              loading: isSaving,
              onTap: () async {
                setDS(() {
                  isSaving = true;
                  errorMsg = null;
                });
                final domainsToSave =
                    (existing == null && domainRestrictionEnabled)
                    ? List<String>.from(allowedDomains)
                    : <String>[];
                final error = existing == null
                    ? await controller.createClass(
                        school: schoolCtrl.text,
                        classCode: codeCtrl.text,
                        subjectName: subjectCtrl.text,
                        allowedEmailDomains: domainsToSave,
                      )
                    : await controller.updateClass(
                        classId: existing.id,
                        school: schoolCtrl.text,
                        classCode: codeCtrl.text,
                        subjectName: subjectCtrl.text,
                      );
                setDS(() => isSaving = false);
                if (!ctx.mounted) return;
                if (error != null) {
                  setDS(() => errorMsg = error);
                } else {
                  Navigator.of(ctx).pop();
                  _toast(
                    title: existing == null ? 'Class Created' : 'Class Updated',
                    message: existing == null
                        ? '"${subjectCtrl.text}" has been created.'
                        : '"${subjectCtrl.text}" has been updated.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  void _showDeleteDialog(ClassModel cls) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedDelete01,
          color: const Color(0xFFE53935),
          size: 28,
        ),
        title: const Text(
          'Delete Class?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete "${cls.subjectName}" '
          '(${cls.classCode}). \nStudent attendance records will remain '
          'in their sessions, but the class itself cannot be recovered.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.black45),
            child: const Text('Cancel'),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();
              final error = await controller.deleteClass(cls.id);
              if (error != null && mounted) {
                _toast(title: 'Error', message: error, isError: true);
              } else if (mounted) {
                _toast(
                  title: 'Deleted',
                  message: '"${cls.subjectName}" has been deleted.',
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showClassDetailDialog(ClassModel cls) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          _ClassDetailDialog(cls: cls, controller: controller, onToast: _toast),
    );
  }
  void _showSettingsDialog(ClassModel cls) {
    int onTimeVal = cls.attendanceSettings.onTimeMinutes;
    int cooldownVal = cls.attendanceSettings.scanCooldownSeconds;
    int timeOutMinVal = cls.attendanceSettings.timeOutMinimumMinutes;
    bool locationVal = cls.attendanceSettings.locationValidation;
    int proximityVal = cls.attendanceSettings.proximityThreshold;
    String? errorMsg;
    bool isSaving = false;
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
              HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                color: const Color(0xFFAEEA00),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      cls.classCode,
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAEEA00).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFAEEA00).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'This threshold applies relative to the session\'s '
                    'Start Time recorded in the Kiosk.\n\n'
                    '● Present (On-Time) — scanned within the on-time window\n'
                    '● Present (Late)       — scanned after the on-time window\n'
                    '● Absent                  — never scanned',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                        color: Color(0xFFB71C1C),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _MinutePicker(
                  label: 'On-Time window',
                  sublabel:
                      'Students are On-Time if they scan within this '
                      'many minutes after session start.',
                  dotColor: const Color(0xFF43A047),
                  value: onTimeVal,
                  onChanged: (v) => setDS(() => onTimeVal = v),
                ),
                const SizedBox(height: 16),
                _SecondPicker(
                  label: 'Scan cooldown',
                  sublabel:
                      'Seconds before the same student can scan again '
                      '(prevents accidental double-scans).',
                  dotColor: const Color(0xFF1565C0),
                  value: cooldownVal,
                  onChanged: (v) => setDS(() => cooldownVal = v),
                ),
                const SizedBox(height: 16),
                _MinutePicker(
                  label: 'Time-Out minimum',
                  sublabel:
                      'Minimum minutes a student must wait after '
                      'Time In before they can Time Out.',
                  dotColor: const Color(0xFF6A1B9A),
                  value: timeOutMinVal,
                  onChanged: (v) => setDS(() => timeOutMinVal = v),
                ),
                const SizedBox(height: 20),
                _LocationValidationToggle(
                  value: locationVal,
                  proximityThreshold: proximityVal,
                  onToggle: (v) => setDS(() => locationVal = v),
                  onProximityChanged: (v) => setDS(() => proximityVal = v),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
              child: const Text('Cancel'),
            ),
            _gradientButton(
              label: 'Save Settings',
              loading: isSaving,
              onTap: () async {
                setDS(() {
                  isSaving = true;
                  errorMsg = null;
                });
                final error = await controller.saveAttendanceSettings(
                  classId: cls.id,
                  onTimeMinutes: onTimeVal,
                  scanCooldownSeconds: cooldownVal,
                  timeOutMinimumMinutes: timeOutMinVal,
                  locationValidation: locationVal,
                  proximityThreshold: proximityVal,
                );
                setDS(() => isSaving = false);
                if (!ctx.mounted) return;
                if (error != null) {
                  setDS(() => errorMsg = error);
                } else {
                  Navigator.of(ctx).pop();
                  _toast(
                    title: 'Settings Saved',
                    message:
                        'Attendance threshold updated for '
                        '"${cls.subjectName}".',
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
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) return const ClassesShimmer();
        return Stack(
          children: [
            Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: controller.classes.isEmpty
                      ? _buildEmptyState(context)
                      : _buildList(context),
                ),
              ],
            ),
            Positioned(
              bottom: 32,
              right: 32,
              child: GestureDetector(
                onTap: () => _showClassDialog(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFAEEA00).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          color: Colors.black,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'New Class',
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
            ),
          ],
        );
      },
    );
  }
  Widget _buildTopBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Padding(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(16, 14, 16, 10)
          : EdgeInsets.fromLTRB(
              _w(context, 0.025),
              _h(context, 0.018),
              _w(context, 0.025),
              _h(context, 0.012),
            ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : _w(context, 0.010),
                vertical: isMobile ? 2 : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: Colors.black38,
                    size: isMobile ? 20 : _fs(context, 0.015),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : _fs(context, 0.013),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search classes...',
                        border: InputBorder.none,
                        isDense: !isMobile,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isMobile ? 14 : 12,
                        ),
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        controller.updateSearch('');
                      },
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: Colors.black26,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: _w(context, 0.012)),
          Text(
            '${controller.classes.length} class${controller.classes.length == 1 ? '' : 'es'}',
            style: TextStyle(
              color: Colors.black38,
              fontSize: _fs(context, 0.012),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildList(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return ListView.builder(
      padding: isMobile
          ? const EdgeInsets.fromLTRB(16, 0, 16, 100)
          : EdgeInsets.fromLTRB(_w(context, 0.025), 0, _w(context, 0.025), 100),
      itemCount: controller.classes.length,
      itemBuilder: (_, i) => _buildClassCard(context, controller.classes[i]),
    );
  }
  Widget _buildClassCard(BuildContext context, ClassModel cls) {
    final pendingCount = cls.pendingStudents.length;
    final enrolledCount = cls.enrolledStudents.length;
    final settings = cls.attendanceSettings;
    final hasDomainRestriction = cls.allowedEmailDomains.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFAEEA00), Color(0xFF76C442)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.subjectName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width < 700
                              ? 14
                              : _fs(context, 0.014),
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${cls.school}  ·  ${cls.classCode}',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize:
                                    MediaQuery.of(context).size.width < 700
                                    ? 11
                                    : _fs(context, 0.011),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasDomainRestriction) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1565C0,
                                ).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedMail01,
                                    color: const Color(0xFF1565C0),
                                    size: 11,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Domain restricted',
                                    style: const TextStyle(
                                      color: Color(0xFF1565C0),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _chip(
                  '$enrolledCount enrolled',
                  const Color(0xFFAEEA00),
                  const Color(0xFF5A8A00),
                ),
                if (pendingCount > 0 &&
                    MediaQuery.of(context).size.width >= 500) ...[
                  const SizedBox(width: 6),
                  _chip(
                    '$pendingCount pending',
                    Colors.orange.shade100,
                    Colors.orange.shade800,
                  ),
                ],
                const SizedBox(width: 8),
                _iconBtn(
                  icon: HugeIcons.strokeRoundedSettings01,
                  tooltip: 'Class Settings',
                  onTap: () => _showClassDetailDialog(cls),
                ),
                const SizedBox(width: 4),
                _iconBtn(
                  icon: HugeIcons.strokeRoundedEdit01,
                  tooltip: 'Edit Class',
                  onTap: () => _showClassDialog(existing: cls),
                ),
                const SizedBox(width: 4),
                _iconBtn(
                  icon: HugeIcons.strokeRoundedDelete01,
                  tooltip: 'Delete Class',
                  color: const Color(0xFFE53935),
                  bg: const Color(0xFFFFEBEE),
                  onTap: () => _showDeleteDialog(cls),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showSettingsDialog(cls),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      color: Colors.black38,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    if (MediaQuery.of(context).size.width >= 500)
                      Text(
                        'Attendance thresholds:',
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: _fs(context, 0.010),
                        ),
                      ),
                    const SizedBox(width: 8),
                    _thresholdLabel(
                      'On-Time ≤ ${settings.onTimeMinutes} min',
                      const Color(0xFF43A047),
                    ),
                    const Spacer(),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: const Color(0xFF5A8A00),
                        fontSize: _fs(context, 0.010),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: const Color(0xFF5A8A00),
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
  Widget _thresholdLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  Widget _iconBtn({
    required List<List<dynamic>> icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.black54,
    Color bg = const Color(0xFFF5F5F5),
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(icon: icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }
  Widget _dialogField({
    required TextEditingController ctrl,
    required String label,
    required List<List<dynamic>> icon,
    String? hint,
    bool enabled = true,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: enabled ? const Color(0xFFF5F5F5) : const Color(0xFFEEEEEE),
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
          borderSide: const BorderSide(color: Color(0xFFAEEA00)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
    );
  }
  Widget _gradientButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
        ),
      ),
    );
  }
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSchoolReportCard,
            color: Colors.black12,
            size: _fs(context, 0.055),
          ),
          const SizedBox(height: 16),
          const Text(
            'No classes yet.',
            style: TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "New Class" to get started.',
            style: TextStyle(color: Colors.black26, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
class _DomainRestrictionSection extends StatelessWidget {
  final bool enabled;
  final List<String> domains;
  final TextEditingController inputCtrl;
  final String? inputError;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAddDomain;
  final void Function(String domain) onRemoveDomain;
  final bool isCreating;
  const _DomainRestrictionSection({
    required this.enabled,
    required this.domains,
    required this.inputCtrl,
    required this.inputError,
    required this.onToggle,
    required this.onAddDomain,
    required this.onRemoveDomain,
    this.isCreating = false,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Domain Restriction',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Only students with an allowed email domain can join.',
                    style: TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isCreating)
              GestureDetector(
                onTap: () => onToggle(!enabled),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 24,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: enabled
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFE0E0E0),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: enabled
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Enabled',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (enabled || !isCreating) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF1565C0).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1565C0),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCreating
                        ? 'Any student whose email does not end with one of '
                              'the domains below will be rejected when trying to '
                              'join this class by code. The teacher\'s manual '
                              'enroll-by-email also enforces this restriction.'
                        : 'Students must use one of the listed email domains '
                              'to join. You can add or remove domains. '
                              'Removing a domain does not unenroll current students.',
                    style: const TextStyle(
                      color: Color(0xFF0D47A1),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: inputCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. fatima.edu.ph',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        prefixText: '@  ',
                        prefixStyle: const TextStyle(
                          color: Colors.black45,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
                            color: Color(0xFF1565C0),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                      onSubmitted: (_) => onAddDomain(),
                    ),
                    if (inputError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        inputError!,
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAddDomain,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (domains.isEmpty)
            const Text(
              'No domains added yet. Add at least one to restrict access.',
              style: TextStyle(color: Colors.black38, fontSize: 11),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: domains.map((d) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.alternate_email_rounded,
                        color: Color(0xFF1565C0),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        d,
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => onRemoveDomain(d),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(
                              Icons.close_rounded,
                              color: isCreating
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFFE53935),
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ],
    );
  }
}
class _ClassDetailDialog extends StatefulWidget {
  final ClassModel cls;
  final ClassesController controller;
  final void Function({
    required String title,
    required String message,
    bool isError,
  })
  onToast;
  const _ClassDetailDialog({
    required this.cls,
    required this.controller,
    required this.onToast,
  });
  @override
  State<_ClassDetailDialog> createState() => _ClassDetailDialogState();
}
class _ClassDetailDialogState extends State<_ClassDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<EnrolledStudent>? _enrolled;
  List<EnrolledStudent>? _pending;
  bool _loadingStudents = true;
  final TextEditingController _emailCtrl = TextEditingController();
  bool _enrolling = false;
  String? _enrollError;
  late List<String> _currentDomains;
  final TextEditingController _domainInputCtrl = TextEditingController();
  String? _domainInputError;
  bool _savingDomain = false;
  late int _onTimeMinutes;
  late int _scanCooldownSeconds;
  late int _timeOutMinimumMinutes;
  late bool _locationValidation;
  late int _proximityThreshold;
  bool _savingSettings = false;
  String? _settingsError;
  String? _settingsSuccess;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _onTimeMinutes = widget.cls.attendanceSettings.onTimeMinutes;
    _scanCooldownSeconds = widget.cls.attendanceSettings.scanCooldownSeconds;
    _timeOutMinimumMinutes =
        widget.cls.attendanceSettings.timeOutMinimumMinutes;
    _locationValidation = widget.cls.attendanceSettings.locationValidation;
    _proximityThreshold = widget.cls.attendanceSettings.proximityThreshold;
    _currentDomains = List<String>.from(widget.cls.allowedEmailDomains);
    _loadStudents();
  }
  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _domainInputCtrl.dispose();
    super.dispose();
  }
  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    final freshClass = await widget.controller.fetchClassDoc(widget.cls.id);
    final enrolledUIDs =
        freshClass?.enrolledStudents ?? widget.cls.enrolledStudents;
    final pendingUIDs =
        freshClass?.pendingStudents ?? widget.cls.pendingStudents;
    if (freshClass != null) {
      _currentDomains = List<String>.from(freshClass.allowedEmailDomains);
    }
    final enrolled = await widget.controller.fetchEnrolledStudents(
      enrolledUIDs,
    );
    final pending = await widget.controller.fetchEnrolledStudents(pendingUIDs);
    if (mounted) {
      setState(() {
        _enrolled = enrolled;
        _pending = pending;
        _loadingStudents = false;
      });
    }
  }
  Future<void> _enrollByEmail() async {
    setState(() {
      _enrolling = true;
      _enrollError = null;
    });
    final error = await widget.controller.enrollStudentByEmail(
      classId: widget.cls.id,
      email: _emailCtrl.text,
    );
    if (!mounted) return;
    if (error == null) {
      _emailCtrl.clear();
      await _loadStudents();
      if (!mounted) return;
      setState(() => _enrolling = false);
      widget.onToast(title: 'Enrolled', message: 'Student has been enrolled.');
    } else {
      setState(() {
        _enrolling = false;
        _enrollError = error;
      });
    }
  }
  Future<void> _addDomain() async {
    final raw = _domainInputCtrl.text;
    final validationErr = ClassesController.validateEmailDomain(raw);
    if (validationErr != null) {
      setState(() => _domainInputError = validationErr);
      return;
    }
    final normalized = raw.trim().toLowerCase();
    if (_currentDomains.contains(normalized)) {
      setState(() => _domainInputError = 'Domain already added.');
      return;
    }
    setState(() {
      _savingDomain = true;
      _domainInputError = null;
    });
    final error = await widget.controller.addAllowedDomain(
      classId: widget.cls.id,
      domain: normalized,
    );
    if (!mounted) return;
    if (error == null) {
      _domainInputCtrl.clear();
      await _loadStudents();
      if (!mounted) return;
      setState(() => _savingDomain = false);
      widget.onToast(
        title: 'Domain Added',
        message: '@$normalized has been added to the allowed list.',
      );
    } else {
      setState(() {
        _savingDomain = false;
        _domainInputError = error;
      });
    }
  }
  Future<void> _showRemoveDomainDialog(String domain) async {
    final affectedCount = await widget.controller.countStudentsWithDomain(
      classId: widget.cls.id,
      domain: domain,
    );
    if (!mounted) return;
    final confirmCtrl = TextEditingController();
    bool removing = false;
    String? inputError;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.alternate_email_rounded,
            color: Color(0xFFE53935),
            size: 32,
          ),
          title: Text(
            'Remove @$domain?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFF57F17),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            affectedCount == 0
                                ? 'No enrolled students use this domain.'
                                : 'This affects $affectedCount currently '
                                      'enrolled student${affectedCount == 1 ? '' : 's'} ',
                            style: const TextStyle(
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Already-enrolled students will NOT be removed — '
                        'they can still access the class normally. '
                        'However, no new students with this domain will '
                        'be able to join going forward.',
                        style: TextStyle(
                          color: Color(0xFF5D4037),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Type DELETE to confirm:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) {
                    if (inputError != null) setDS(() => inputError = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    hintStyle: const TextStyle(
                      color: Colors.black26,
                      fontSize: 13,
                    ),
                    errorText: inputError,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
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
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: removing ? null : () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
              child: const Text('Cancel'),
            ),
            GestureDetector(
              onTap: removing
                  ? null
                  : () async {
                      if (confirmCtrl.text.trim() != 'DELETE') {
                        setDS(
                          () => inputError =
                              'Type DELETE (in capitals) to confirm.',
                        );
                        return;
                      }
                      setDS(() => removing = true);
                      final error = await widget.controller.removeAllowedDomain(
                        classId: widget.cls.id,
                        domain: domain,
                      );
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (error != null) {
                        widget.onToast(
                          title: 'Error',
                          message: error,
                          isError: true,
                        );
                      } else {
                        await _loadStudents();
                        if (!mounted) return;
                        widget.onToast(
                          title: 'Domain Removed',
                          message:
                              '@$domain has been removed. '
                              'Existing students are unaffected.',
                        );
                      }
                    },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: removing ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
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
                          'Remove Domain',
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
  Future<void> _saveSettings() async {
    setState(() {
      _savingSettings = true;
      _settingsError = null;
      _settingsSuccess = null;
    });
    final error = await widget.controller.saveAttendanceSettings(
      classId: widget.cls.id,
      onTimeMinutes: _onTimeMinutes,
      scanCooldownSeconds: _scanCooldownSeconds,
      timeOutMinimumMinutes: _timeOutMinimumMinutes,
      locationValidation: _locationValidation,
      proximityThreshold: _proximityThreshold,
    );
    if (mounted) {
      setState(() {
        _savingSettings = false;
        if (error != null) {
          _settingsError = error;
        } else {
          _settingsSuccess = 'Settings saved successfully.';
        }
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width < 700
            ? MediaQuery.of(context).size.width * 0.92
            : 520,
        height: MediaQuery.of(context).size.width < 700
            ? MediaQuery.of(context).size.height * 0.85
            : 600,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedSchoolReportCard,
                    color: const Color(0xFFAEEA00),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cls.subjectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          widget.cls.classCode,
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.black38,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              labelColor: const Color(0xFF5A8A00),
              unselectedLabelColor: Colors.black38,
              indicatorColor: const Color(0xFFAEEA00),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Students'),
                Tab(text: 'Attendance Settings'),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [_buildStudentsTab(), _buildSettingsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStudentsTab() {
    if (_loadingStudents) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFAEEA00)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DomainRestrictionSection(
          enabled: _currentDomains.isNotEmpty,
          domains: _currentDomains,
          inputCtrl: _domainInputCtrl,
          inputError: _domainInputError,
          onToggle: (_) {},
          onAddDomain: _savingDomain ? () {} : _addDomain,
          onRemoveDomain: _showRemoveDomainDialog,
          isCreating: false,
        ),
        if (_savingDomain)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              color: Color(0xFF1565C0),
              backgroundColor: Color(0xFFE3F2FD),
            ),
          ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),
        const Text(
          'Enroll by Email',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'student@email.com',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
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
                    borderSide: const BorderSide(color: Color(0xFFAEEA00)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _enrolling ? null : _enrollByEmail,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _enrolling
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Enroll',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        if (_enrollError != null) ...[
          const SizedBox(height: 6),
          Text(
            _enrollError!,
            style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        if (_pending != null && _pending!.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Pending Approval',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_pending!.length}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._pending!.map((s) => _pendingRow(s)),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            const Text(
              'Enrolled Students',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFAEEA00).withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_enrolled?.length ?? 0}',
                style: const TextStyle(
                  color: Color(0xFF5A8A00),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_enrolled == null || _enrolled!.isEmpty)
          const Text(
            'No students enrolled yet.',
            style: TextStyle(color: Colors.black38, fontSize: 13),
          )
        else
          ..._enrolled!.map((s) => _enrolledRow(s)),
      ],
    );
  }
  Widget _pendingRow(EnrolledStudent s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  s.email,
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final error = await widget.controller.approvePendingStudent(
                classId: widget.cls.id,
                studentUID: s.uid,
              );
              if (!mounted) return;
              if (error == null) {
                await _loadStudents();
                if (!mounted) return;
                widget.onToast(
                  title: 'Approved',
                  message: '${s.fullName} has been enrolled.',
                );
              } else {
                widget.onToast(title: 'Error', message: error, isError: true);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFAEEA00).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Approve',
                  style: TextStyle(
                    color: Color(0xFF5A8A00),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              final error = await widget.controller.declinePendingStudent(
                classId: widget.cls.id,
                studentUID: s.uid,
              );
              if (!mounted) return;
              if (error == null) {
                await _loadStudents();
                if (!mounted) return;
                widget.onToast(
                  title: 'Declined',
                  message: "${s.fullName}'s request was declined.",
                );
              } else {
                widget.onToast(title: 'Error', message: error, isError: true);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: const Color(0xFFE53935),
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _enrolledRow(EnrolledStudent s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  s.email,
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final error = await widget.controller.removeStudent(
                classId: widget.cls.id,
                studentUID: s.uid,
              );
              if (!mounted) return;
              if (error == null) {
                await _loadStudents();
                if (!mounted) return;
                widget.onToast(
                  title: 'Removed',
                  message: '${s.fullName} has been removed.',
                );
              } else {
                widget.onToast(title: 'Error', message: error, isError: true);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUserRemove01,
                  color: const Color(0xFFE53935),
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFAEEA00).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFAEEA00).withValues(alpha: 0.3),
            ),
          ),
          child: const Text(
            'This threshold is applied relative to the session\'s '
            'Start Time as recorded by the Kiosk when a session begins.\n\n'
            '● Present (On-Time) — student scans ≤ On-Time window after start\n'
            '● Present (Late)       — student scans after the On-Time window\n'
            '● Absent                  — student never scans at all',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.65),
          ),
        ),
        const SizedBox(height: 24),
        if (_settingsError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _settingsError!,
              style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_settingsSuccess != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFAEEA00).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _settingsSuccess!,
              style: const TextStyle(color: Color(0xFF5A8A00), fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _MinutePicker(
          label: 'On-Time window',
          sublabel:
              'Students are On-Time if they scan within this many '
              'minutes after session start.',
          dotColor: const Color(0xFF43A047),
          value: _onTimeMinutes,
          onChanged: (v) => setState(() {
            _onTimeMinutes = v;
            _settingsSuccess = null;
            _settingsError = null;
          }),
        ),
        const SizedBox(height: 20),
        _SecondPicker(
          label: 'Scan cooldown',
          sublabel:
              'Seconds before the same student can scan again '
              '(prevents accidental double-scans).',
          dotColor: const Color(0xFF1565C0),
          value: _scanCooldownSeconds,
          onChanged: (v) => setState(() {
            _scanCooldownSeconds = v;
            _settingsSuccess = null;
            _settingsError = null;
          }),
        ),
        const SizedBox(height: 20),
        _MinutePicker(
          label: 'Time-Out minimum',
          sublabel:
              'Minimum minutes a student must wait after '
              'Time In before they can Time Out.',
          dotColor: const Color(0xFF6A1B9A),
          value: _timeOutMinimumMinutes,
          onChanged: (v) => setState(() {
            _timeOutMinimumMinutes = v;
            _settingsSuccess = null;
            _settingsError = null;
          }),
        ),
        const SizedBox(height: 20),
        _LocationValidationToggle(
          value: _locationValidation,
          proximityThreshold: _proximityThreshold,
          onToggle: (v) => setState(() {
            _locationValidation = v;
            _settingsSuccess = null;
            _settingsError = null;
          }),
          onProximityChanged: (v) => setState(() {
            _proximityThreshold = v;
            _settingsSuccess = null;
            _settingsError = null;
          }),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _savingSettings ? null : _saveSettings,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _savingSettings
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Save Settings',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _MinutePicker extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color dotColor;
  final int value;
  final ValueChanged<int> onChanged;
  const _MinutePicker({
    required this.label,
    required this.sublabel,
    required this.dotColor,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => onChanged((value - 1).clamp(0, 120)),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Text(
                '$value min',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: dotColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onChanged((value + 1).clamp(0, 120)),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sublabel,
          style: const TextStyle(color: Colors.black38, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: dotColor,
            inactiveTrackColor: dotColor.withValues(alpha: 0.15),
            thumbColor: dotColor,
            overlayColor: dotColor.withValues(alpha: 0.12),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 120,
            divisions: 120,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
class _LocationValidationToggle extends StatelessWidget {
  final bool value;
  final int proximityThreshold;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onProximityChanged;
  const _LocationValidationToggle({
    required this.value,
    required this.proximityThreshold,
    required this.onToggle,
    required this.onProximityChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Location Validation',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => onToggle(!value),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 24,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: value
                        ? const Color(0xFFE65100)
                        : const Color(0xFFE0E0E0),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Validates that students are physically near the kiosk when scanning.',
          style: TextStyle(color: Colors.black38, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE65100).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE65100),
                size: 14,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPS accuracy varies by device. Phones average 5–20m, '
                  'laptops on WiFi may report 50–300m of error. In areas '
                  'with weak signal, legitimate students may be incorrectly '
                  'rejected. Set a generous threshold if your environment '
                  'has poor GPS coverage. This is a deterrent, not a guarantee.',
                  style: TextStyle(
                    color: Color(0xFFBF360C),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (value) ...[
          const SizedBox(height: 16),
          _MeterPicker(
            label: 'Proximity threshold',
            sublabel:
                'Maximum distance in meters a student can be from '
                'the kiosk to pass validation.',
            dotColor: const Color(0xFFE65100),
            value: proximityThreshold,
            onChanged: onProximityChanged,
          ),
        ],
      ],
    );
  }
}
class _MeterPicker extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color dotColor;
  final int value;
  final ValueChanged<int> onChanged;
  const _MeterPicker({
    required this.label,
    required this.sublabel,
    required this.dotColor,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => onChanged((value - 10).clamp(10, 1000)),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: Text(
                '${value}m',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: dotColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onChanged((value + 10).clamp(10, 1000)),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sublabel,
          style: const TextStyle(color: Colors.black38, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: dotColor,
            inactiveTrackColor: dotColor.withValues(alpha: 0.15),
            thumbColor: dotColor,
            overlayColor: dotColor.withValues(alpha: 0.12),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 10,
            max: 1000,
            divisions: 99,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
class _SecondPicker extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color dotColor;
  final int value;
  final ValueChanged<int> onChanged;
  const _SecondPicker({
    required this.label,
    required this.sublabel,
    required this.dotColor,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => onChanged((value - 1).clamp(1, 120)),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Text(
                '$value sec',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: dotColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onChanged((value + 1).clamp(1, 120)),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sublabel,
          style: const TextStyle(color: Colors.black38, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: dotColor,
            inactiveTrackColor: dotColor.withValues(alpha: 0.15),
            thumbColor: dotColor,
            overlayColor: dotColor.withValues(alpha: 0.12),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

