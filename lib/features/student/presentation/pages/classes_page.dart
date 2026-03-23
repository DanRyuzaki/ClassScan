import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import '../../logic/classes_controller.dart';

class StudentClassesPage extends StatefulWidget {
  const StudentClassesPage({super.key});
  @override
  State<StudentClassesPage> createState() => _StudentClassesPageState();
}

class _StudentClassesPageState extends State<StudentClassesPage> {
  final StudentClassesController controller = StudentClassesController();
  @override
  void dispose() {
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

  void _showJoinDialog() {
    final codeCtrl = TextEditingController();
    bool isJoining = false;
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
                icon: HugeIcons.strokeRoundedSchoolReportCard,
                color: const Color(0xFFAEEA00),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Join a Class',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the class code provided by your teacher. '
                  'Your request will be pending until the teacher approves it.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Class Code',
                    hintText: 'e.g. STEM12-Y1-1P',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCode,
                        color: Colors.black38,
                        size: 18,
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
              onTap: isJoining
                  ? null
                  : () async {
                      setDialogState(() => isJoining = true);
                      final error = await controller.joinClass(codeCtrl.text);
                      setDialogState(() => isJoining = false);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      if (error != null) {
                        _showToast(
                          title: 'Could Not Join',
                          message: error,
                          isError: true,
                        );
                      } else {
                        _showToast(
                          title: 'Request Sent',
                          message:
                              'Your join request is pending teacher approval.',
                        );
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCCFF00), Color(0xFF76C442)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isJoining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Join Class',
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
      ),
    );
  }

  void _showRemoveDialog(StudentClassModel cls) {
    final isPending = cls.isPending;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedInformationCircle,
          color: const Color(0xFFFBC02D),
          size: 28,
        ),
        title: Text(
          isPending ? 'Cancel Request?' : 'Unenroll?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isPending
              ? 'Cancel your pending join request for "${cls.subjectName}"?'
              : 'Are you sure you want to unenroll from "${cls.subjectName}"? '
                    'Your attendance records will not be deleted.',
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
              final error = isPending
                  ? await controller.cancelPendingRequest(cls.id)
                  : await controller.unenrollFromClass(cls.id);
              if (error != null && mounted) {
                _showToast(title: 'Error', message: error, isError: true);
              } else if (mounted) {
                _showToast(
                  title: isPending ? 'Request Cancelled' : 'Unenrolled',
                  message: isPending
                      ? 'Your join request has been cancelled.'
                      : 'You have been unenrolled from ${cls.subjectName}.',
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
              child: Text(
                isPending ? 'Cancel Request' : 'Unenroll',
                style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 700;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: [
            controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFAEEA00)),
                  )
                : controller.classes.isEmpty
                ? _buildEmptyState(isSmall)
                : _buildClassList(isSmall),
            Positioned(
              bottom: isSmall ? 20 : 32,
              right: isSmall ? 20 : 32,
              child: GestureDetector(
                onTap: _showJoinDialog,
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
                          'Join Class',
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

  Widget _buildClassList(bool isSmall) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        isSmall ? 16 : 24,
        isSmall ? 16 : 20,
        isSmall ? 16 : 24,
        100,
      ),
      children: [
        if (controller.enrolledClasses.isNotEmpty) ...[
          _sectionHeader('Enrolled Classes', controller.enrolledClasses.length),
          const SizedBox(height: 10),
          ...controller.enrolledClasses.map(
            (cls) => _buildClassCard(cls, isSmall),
          ),
          const SizedBox(height: 24),
        ],
        if (controller.pendingClasses.isNotEmpty) ...[
          _sectionHeader(
            'Pending Approval',
            controller.pendingClasses.length,
            isPending: true,
          ),
          const SizedBox(height: 10),
          ...controller.pendingClasses.map(
            (cls) => _buildClassCard(cls, isSmall),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, {bool isPending = false}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isPending ? Colors.black45 : Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isPending
                ? Colors.orange.withValues(alpha: 0.12)
                : const Color(0xFFAEEA00).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPending
                  ? Colors.orange.shade700
                  : const Color(0xFF5A8A00),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(StudentClassModel cls, bool isSmall) {
    final isPending = cls.isPending;
    final hasSession = cls.hasActiveSession;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? Colors.orange.withValues(alpha: 0.3)
              : const Color(0xFFE0E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isPending)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasSession
                    ? const Color(0xFF43A047)
                    : const Color(0xFFE53935),
                boxShadow: hasSession
                    ? [
                        BoxShadow(
                          color: const Color(0xFF43A047).withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pending',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.subjectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${cls.school}  ·  ${cls.classCode}',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
                if (!isPending && hasSession) ...[
                  const SizedBox(height: 4),
                  Text(
                    '● Session in progress',
                    style: TextStyle(
                      color: const Color(0xFF43A047),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showRemoveDialog(cls),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: isPending
                      ? HugeIcons.strokeRoundedCancel01
                      : HugeIcons.strokeRoundedUserRemove01,
                  color: const Color(0xFFE53935),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmall) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSchoolReportCard,
              color: Colors.black12,
              size: isSmall ? 60 : 72,
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
              'Tap "Join Class" to request access\nto a class using its code.',
              style: TextStyle(color: Colors.black26, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
