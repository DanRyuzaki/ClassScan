import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:web/web.dart' as web;
import '../../logic/attendance_controller.dart';
import '../../../../core/controllers/dynamicsize_controller.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AttendanceController controller = AttendanceController();
  bool _isExporting = false;
  bool _isForceEnding = false;
  bool _isDeleting = false;
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
    controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (controller.realtimeToast != null) {
      final name = controller.realtimeToast!;
      controller.clearRealtimeToast();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showToast(title: 'Time In', message: '$name just timed in.');
        }
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
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
            : HugeIcons.strokeRoundedUserCheck01,
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

  void _exportToExcel() {
    if (controller.selectedSession == null) return;
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final excel = Excel.createExcel();
    final sheet = excel['Attendance'];
    if (excel.sheets.containsKey('FlutterExcel')) {
      excel.delete('FlutterExcel');
    }
    final headers = ['Name', 'Time In', 'Time Out', 'Status', 'Remark'];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(
        headers[i],
      );
    }
    final data = controller.getExportData();
    for (var r = 0; r < data.length; r++) {
      final row = data[r];
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 1))
          .value = TextCellValue(
        row['Name'] ?? '',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r + 1))
          .value = TextCellValue(
        row['Time In'] ?? '',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r + 1))
          .value = TextCellValue(
        row['Time Out'] ?? '',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r + 1))
          .value = TextCellValue(
        row['Status'] ?? '',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r + 1))
          .value = TextCellValue(
        row['Remark'] ?? '',
      );
    }
    final bytes = excel.encode();
    if (bytes == null) return;
    final cls = controller.selectedClass?.classCode ?? 'class';
    final date = controller.selectedDate ?? 'date';
    final session = controller.selectedSession?.sessionNumber ?? 1;
    final filename = 'Attendance_${cls}_${date}_Session$session.xlsx';
    final uint8 = Uint8List.fromList(bytes);
    final blob = web.Blob(
      [uint8.toJS].toJS,
      web.BlobPropertyBag(
        type:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ),
    );
    final url = web.URL.createObjectURL(blob);
    final a = web.document.createElement('a') as web.HTMLAnchorElement;
    a.href = url;
    a.setAttribute('download', filename);
    web.document.body!.append(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isExporting = false);
    });
  }

  void _showEditDialog(AttendanceRow row) {
    DateTime? timeIn = row.timeIn;
    DateTime? timeOut = row.timeOut;
    final remarkCtrl = TextEditingController(text: row.remark);
    bool isSaving = false;
    String fmtTime(DateTime? dt) {
      if (dt == null) return '';
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $period';
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedUserEdit01,
                color: const Color(0xFFAEEA00),
                size: _fs(context, 0.022),
              ),
              SizedBox(width: _w(context, 0.008)),
              Expanded(
                child: Text(
                  row.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _fs(context, 0.015),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: _w(context, 0.30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTimePicker(
                  context: context,
                  label: 'Time In',
                  value: timeIn,
                  icon: HugeIcons.strokeRoundedClock01,
                  onPick: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: timeIn != null
                          ? TimeOfDay.fromDateTime(timeIn!)
                          : TimeOfDay.now(),
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      setDialogState(() {
                        timeIn = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          picked.hour,
                          picked.minute,
                        );
                      });
                    }
                  },
                  onClear: () => setDialogState(() => timeIn = null),
                  formatFn: fmtTime,
                ),
                SizedBox(height: _h(context, 0.012)),
                _buildTimePicker(
                  context: context,
                  label: 'Time Out',
                  value: timeOut,
                  icon: HugeIcons.strokeRoundedClock02,
                  onPick: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: timeOut != null
                          ? TimeOfDay.fromDateTime(timeOut!)
                          : TimeOfDay.now(),
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      setDialogState(() {
                        timeOut = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          picked.hour,
                          picked.minute,
                        );
                      });
                    }
                  },
                  onClear: () => setDialogState(() => timeOut = null),
                  formatFn: fmtTime,
                ),
                SizedBox(height: _h(context, 0.012)),
                TextField(
                  controller: remarkCtrl,
                  maxLines: 2,
                  style: TextStyle(fontSize: _fs(context, 0.012)),
                  decoration: InputDecoration(
                    labelText: 'Remark (optional)',
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: _fs(context, 0.012),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedNote01,
                        color: Colors.black38,
                        size: _fs(context, 0.016),
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
                      borderSide: const BorderSide(color: Color(0xFFAEEA00)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
              child: const Text('Cancel'),
            ),
            GestureDetector(
              onTap: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final error = await controller.updateAttendance(
                        studentUID: row.studentUID,
                        timeIn: timeIn,
                        timeOut: timeOut,
                        remark: remarkCtrl.text,
                      );
                      setDialogState(() => isSaving = false);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      if (error != null) {
                        _showToast(
                          title: 'Error',
                          message: error,
                          isError: true,
                        );
                      } else {
                        _showToast(
                          title: 'Updated',
                          message: '${row.displayName}\'s attendance saved.',
                        );
                      }
                    },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _w(context, 0.018),
                  vertical: _h(context, 0.010),
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: _fs(context, 0.012),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required List<List<dynamic>> icon,
    required VoidCallback onPick,
    required VoidCallback onClear,
    required String Function(DateTime?) formatFn,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _w(context, 0.010),
            vertical: _h(context, 0.012),
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
                color: Colors.black38,
                size: _fs(context, 0.016),
              ),
              SizedBox(width: _w(context, 0.008)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: _fs(context, 0.010),
                      ),
                    ),
                    Text(
                      value != null ? formatFn(value) : 'Tap to set',
                      style: TextStyle(
                        color: value != null ? Colors.black87 : Colors.black38,
                        fontSize: _fs(context, 0.013),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (value != null)
                GestureDetector(
                  onTap: onClear,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: Colors.black26,
                    size: _fs(context, 0.014),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              children: [
                _buildFilterBar(context),
                if (controller.selectedSession != null)
                  _buildSessionInfoBar(context, controller.selectedSession!),
                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFAEEA00),
                          ),
                        )
                      : controller.selectedSession == null
                      ? _buildEmptyState(context)
                      : _buildTable(context),
                ),
              ],
            ),
            if (controller.selectedSession != null)
              Positioned(
                bottom: MediaQuery.of(context).size.width < 700
                    ? 20
                    : _h(context, 0.04),
                right: MediaQuery.of(context).size.width < 700
                    ? 16
                    : _w(context, 0.03),
                child: GestureDetector(
                  onTap: _isExporting ? null : _exportToExcel,
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
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFAEEA00,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedFileExport,
                            color: Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Export',
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

  Widget _buildSessionInfoBar(BuildContext context, SessionItem session) {
    final isRunning = session.isRunning;
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : _w(context, 0.025),
        vertical: isMobile ? 8.0 : _h(context, 0.011),
      ),
      decoration: BoxDecoration(
        color: isRunning
            ? const Color(0xFF43A047).withValues(alpha: 0.07)
            : const Color(0xFFF5F5F5),
        border: Border(
          bottom: BorderSide(
            color: isRunning
                ? const Color(0xFF43A047).withValues(alpha: 0.25)
                : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sessionInfoItems(context, session, isRunning),
              ),
            )
          : Row(
              children: [
                ..._sessionInfoItems(context, session, isRunning, spacer: true),
              ],
            ),
    );
  }

  List<Widget> _sessionInfoItems(
    BuildContext context,
    SessionItem session,
    bool isRunning, {
    bool spacer = false,
  }) {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isRunning
              ? const Color(0xFF43A047).withValues(alpha: 0.15)
              : const Color(0xFFE0E0E0).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRunning ? const Color(0xFF43A047) : Colors.black38,
                boxShadow: isRunning
                    ? [
                        BoxShadow(
                          color: const Color(0xFF43A047).withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isRunning ? 'Session Running' : 'Session Ended',
              style: TextStyle(
                fontSize: _fs(context, 0.011),
                fontWeight: FontWeight.w700,
                color: isRunning ? const Color(0xFF2E7D32) : Colors.black45,
              ),
            ),
          ],
        ),
      ),
      SizedBox(width: _w(context, 0.02).clamp(12, 28)),
      _sessionInfoChip(
        context: context,
        icon: HugeIcons.strokeRoundedClock01,
        label: 'Started',
        value: session.formattedStartTime,
        color: const Color(0xFF1565C0),
      ),
      SizedBox(width: _w(context, 0.012).clamp(8, 20)),
      _sessionInfoChip(
        context: context,
        icon: HugeIcons.strokeRoundedClock02,
        label: 'Ended',
        value: isRunning ? 'In progress...' : session.formattedEndTime,
        color: isRunning ? Colors.black38 : const Color(0xFFB71C1C),
        dimmed: isRunning,
      ),
      SizedBox(width: _w(context, 0.012).clamp(8, 20)),
      _sessionInfoChip(
        context: context,
        icon: HugeIcons.strokeRoundedCalendar01,
        label: 'Date',
        value: session.date,
        color: Colors.black54,
      ),
      if (spacer) const Spacer(),
      if (isRunning) ...[
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _isForceEnding ? null : () => _showForceEndDialog(session),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isForceEnding ? 0.5 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isForceEnding)
                      const SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedStopWatch,
                        color: Colors.white,
                        size: _fs(context, 0.012),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'Force End',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: _fs(context, 0.011),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      const SizedBox(width: 8),
      GestureDetector(
        onTap: _isDeleting ? null : () => _showDeleteSessionDialog(session),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isDeleting ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isDeleting)
                    const SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE53935),
                      ),
                    )
                  else
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete01,
                      color: const Color(0xFFE53935),
                      size: _fs(context, 0.012),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.w700,
                      fontSize: _fs(context, 0.011),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  void _showForceEndDialog(SessionItem session) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedAlertCircle,
          color: const Color(0xFFE53935),
          size: 28,
        ),
        title: const Text(
          'Force End Session?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Text(
          'This will remotely end ${session.label} and stop all QR scanning '
          'on the kiosk immediately. The kiosk will be notified in real-time.\n'
          'Use this if the kiosk is unreachable (e.g. battery died).',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.black45),
            child: const Text('Cancel'),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();
              setState(() => _isForceEnding = true);
              final error = await controller.forceEndSession();
              if (mounted) {
                setState(() => _isForceEnding = false);
                if (error != null) {
                  _showToast(title: 'Error', message: error, isError: true);
                } else {
                  _showToast(
                    title: 'Session Ended',
                    message: 'The session has been force-ended remotely.',
                  );
                }
              }
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
              child: const Text(
                'Force End',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSessionDialog(SessionItem session) {
    final codeCtrl = TextEditingController();
    final classCode = controller.selectedClass?.classCode ?? '';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedDelete01,
            color: const Color(0xFFE53935),
            size: 28,
          ),
          title: const Text(
            'Delete Session?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This will permanently delete ${session.label} and all its '
                'attendance records. This cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      color: const Color(0xFFE53935),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Type "$classCode" to confirm.',
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setDS(() {}),
                decoration: InputDecoration(
                  hintText: classCode,
                  hintStyle: const TextStyle(color: Colors.black26),
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
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
              child: const Text('Cancel'),
            ),
            GestureDetector(
              onTap: codeCtrl.text.trim() == classCode
                  ? () async {
                      Navigator.of(context).pop();
                      setState(() => _isDeleting = true);
                      final error = await controller.deleteSession();
                      if (mounted) {
                        setState(() => _isDeleting = false);
                        if (error != null) {
                          _showToast(
                            title: 'Error',
                            message: error,
                            isError: true,
                          );
                        } else {
                          _showToast(
                            title: 'Deleted',
                            message: '${session.label} has been deleted.',
                          );
                        }
                      }
                    }
                  : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: codeCtrl.text.trim() == classCode ? 1.0 : 0.35,
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
    ).then((_) => codeCtrl.dispose());
  }

  Widget _sessionInfoChip({
    required BuildContext context,
    required List<List<dynamic>> icon,
    required String label,
    required String value,
    required Color color,
    bool dimmed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          color: dimmed ? Colors.black26 : color.withValues(alpha: 0.7),
          size: _fs(context, 0.013),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: _fs(context, 0.009),
                color: Colors.black38,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: _fs(context, 0.011),
                fontWeight: FontWeight.w600,
                color: dimmed ? Colors.black38 : color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final hPad = isMobile ? 16.0 : _w(context, 0.025);
    final vPad = isMobile ? 12.0 : _h(context, 0.018);
    final gap = isMobile ? 10.0 : _w(context, 0.012);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      color: Colors.white,
      child: isMobile
          ? Column(
              children: [
                _buildDropdown<ClassItem>(
                  context: context,
                  hint: 'Select Class',
                  value: controller.selectedClass,
                  items: controller.classes,
                  labelFn: (c) => c.label,
                  onChanged: (c) {
                    if (c != null) controller.selectClass(c);
                  },
                  icon: HugeIcons.strokeRoundedSchoolReportCard,
                ),
                SizedBox(height: gap),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<String>(
                        context: context,
                        hint: 'Select Date',
                        value: controller.selectedDate,
                        items: controller.availableDates,
                        labelFn: (d) => d,
                        onChanged: (d) {
                          if (d != null) controller.selectDate(d);
                        },
                        icon: HugeIcons.strokeRoundedCalendar01,
                        enabled: controller.selectedClass != null,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _buildDropdown<SessionItem>(
                        context: context,
                        hint: 'Select Session',
                        value: controller.selectedSession,
                        items: controller.sessions,
                        labelFn: (s) => s.label,
                        onChanged: (s) {
                          if (s != null) controller.selectSession(s);
                        },
                        icon: HugeIcons.strokeRoundedQrCode,
                        enabled: controller.selectedDate != null,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildDropdown<ClassItem>(
                    context: context,
                    hint: 'Select Class',
                    value: controller.selectedClass,
                    items: controller.classes,
                    labelFn: (c) => c.label,
                    onChanged: (c) {
                      if (c != null) controller.selectClass(c);
                    },
                    icon: HugeIcons.strokeRoundedSchoolReportCard,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  flex: 2,
                  child: _buildDropdown<String>(
                    context: context,
                    hint: 'Select Date',
                    value: controller.selectedDate,
                    items: controller.availableDates,
                    labelFn: (d) => d,
                    onChanged: (d) {
                      if (d != null) controller.selectDate(d);
                    },
                    icon: HugeIcons.strokeRoundedCalendar01,
                    enabled: controller.selectedClass != null,
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  flex: 2,
                  child: _buildDropdown<SessionItem>(
                    context: context,
                    hint: 'Select Session',
                    value: controller.selectedSession,
                    items: controller.sessions,
                    labelFn: (s) => s.label,
                    onChanged: (s) {
                      if (s != null) controller.selectSession(s);
                    },
                    icon: HugeIcons.strokeRoundedQrCode,
                    enabled: controller.selectedDate != null,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) labelFn,
    required ValueChanged<T?> onChanged,
    required List<List<dynamic>> icon,
    bool enabled = true,
  }) {
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _w(context, 0.010)),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    color: Colors.black38,
                    size: _fs(context, 0.014),
                  ),
                  SizedBox(width: _w(context, 0.006)),
                  Text(
                    hint,
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: _fs(context, 0.012),
                    ),
                  ),
                ],
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelFn(item),
                    style: TextStyle(fontSize: _fs(context, 0.012)),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final hPad = isMobile ? 16.0 : _w(context, 0.025);
    final vPad = isMobile ? 12.0 : _h(context, 0.016);
    if (isMobile) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 80),
        child: controller.rows.isEmpty
            ? Center(
                child: Text(
                  'No students enrolled in this class.',
                  style: TextStyle(color: Colors.black38, fontSize: 13),
                ),
              )
            : ListView.separated(
                itemCount: controller.rows.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _buildMobileCard(context, controller.rows[i]),
              ),
      );
    }
    const tableMinWidth = 700.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth < tableMinWidth
              ? tableMinWidth
              : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _buildTableHeader(context),
                  Expanded(
                    child: controller.rows.isEmpty
                        ? Center(
                            child: Text(
                              'No students enrolled in this class.',
                              style: TextStyle(
                                color: Colors.black38,
                                fontSize: _fs(context, 0.013),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: controller.rows.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: Color(0xFFF0F0F0),
                            ),
                            itemBuilder: (_, i) =>
                                _buildTableRow(context, controller.rows[i]),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context, AttendanceRow row) {
    String fmtTime(DateTime? dt) {
      if (dt == null) return 'N/A';
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $period';
    }

    final Color cardColor = row.isAbsent
        ? const Color(0xFFFFEBEE)
        : row.isLate
        ? const Color(0xFFFFF3E0)
        : Colors.white;
    return GestureDetector(
      onTap: () => _showEditDialog(row),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      row.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context, row),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _mobileCardChip(
                    icon: HugeIcons.strokeRoundedClock01,
                    label: 'In',
                    value: fmtTime(row.timeIn),
                    color: row.timeIn != null ? Colors.black87 : Colors.black38,
                  ),
                  const SizedBox(width: 16),
                  _mobileCardChip(
                    icon: HugeIcons.strokeRoundedClock02,
                    label: 'Out',
                    value: fmtTime(row.timeOut),
                    color: row.timeOut != null
                        ? Colors.black87
                        : Colors.black38,
                  ),
                ],
              ),
              if (row.remark.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Remark: ${row.remark}',
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileCardChip({
    required List<List<dynamic>> icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(icon: icon, color: Colors.black38, size: 13),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.black38, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _w(context, 0.015),
        vertical: _h(context, 0.012),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFAEEA00).withValues(alpha: 0.12),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _sortableHeader(context, 'Name', SortColumn.name, flex: 3),
          _sortableHeader(context, 'Time In', SortColumn.timeIn, flex: 2),
          _sortableHeader(context, 'Time Out', SortColumn.timeOut, flex: 2),
          _sortableHeader(context, 'Status', SortColumn.status, flex: 1),
          Expanded(
            flex: 2,
            child: Text(
              'Remark',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: _fs(context, 0.011),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortableHeader(
    BuildContext context,
    String label,
    SortColumn column, {
    int flex = 1,
  }) {
    final isActive = controller.sortColumn == column;
    final isAsc = controller.sortDirection == SortDirection.asc;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => controller.toggleSort(column),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF5A8A00) : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: _fs(context, 0.011),
                ),
              ),
              const SizedBox(width: 4),
              if (isActive)
                HugeIcon(
                  icon: isAsc
                      ? HugeIcons.strokeRoundedArrowUp01
                      : HugeIcons.strokeRoundedArrowDown01,
                  color: const Color(0xFF5A8A00),
                  size: _fs(context, 0.011),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, AttendanceRow row) {
    final isAbsent = row.isAbsent;
    String fmtTime(DateTime? dt) {
      if (dt == null) return 'N/A';
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $period';
    }

    return GestureDetector(
      onTap: () => _showEditDialog(row),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          color: isAbsent
              ? const Color(0xFFFFEBEE)
              : row.isLate
              ? const Color(0xFFFFF3E0)
              : Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: _w(context, 0.015),
            vertical: _h(context, 0.014),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  row.displayName,
                  style: TextStyle(
                    fontSize: _fs(context, 0.012),
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  fmtTime(row.timeIn),
                  style: TextStyle(
                    fontSize: _fs(context, 0.012),
                    color: row.timeIn != null ? Colors.black87 : Colors.black38,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  fmtTime(row.timeOut),
                  style: TextStyle(
                    fontSize: _fs(context, 0.012),
                    color: row.timeOut != null
                        ? Colors.black87
                        : Colors.black38,
                  ),
                ),
              ),
              Expanded(flex: 1, child: _buildStatusBadge(context, row)),
              Expanded(
                flex: 2,
                child: Text(
                  row.remark.isNotEmpty ? row.remark : '—',
                  style: TextStyle(
                    fontSize: _fs(context, 0.011),
                    color: Colors.black45,
                    fontStyle: row.remark.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, AttendanceRow row) {
    final Color bgColor;
    final Color textColor;
    if (row.isAbsent) {
      bgColor = const Color(0xFFE53935).withValues(alpha: 0.12);
      textColor = const Color(0xFFB71C1C);
    } else if (row.isLate) {
      bgColor = const Color(0xFFFF6F00).withValues(alpha: 0.12);
      textColor = const Color(0xFFE65100);
    } else {
      bgColor = const Color(0xFF43A047).withValues(alpha: 0.13);
      textColor = const Color(0xFF1B5E20);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        row.status,
        style: TextStyle(
          fontSize: _fs(context, 0.010),
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUserAccount,
            color: Colors.black12,
            size: _fs(context, 0.055),
          ),
          SizedBox(height: _h(context, 0.015)),
          Text(
            controller.selectedClass == null
                ? 'Select a class to view attendance.'
                : controller.selectedDate == null
                ? 'Select a date.'
                : 'Select a session.',
            style: TextStyle(
              color: Colors.black38,
              fontSize: _fs(context, 0.014),
            ),
          ),
        ],
      ),
    );
  }
}
