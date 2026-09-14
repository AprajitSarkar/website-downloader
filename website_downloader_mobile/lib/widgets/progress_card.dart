import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/download_task.dart';

class ProgressCard extends StatefulWidget {
  final DownloadTask task;
  final VoidCallback? onCancel;
  final VoidCallback? onOpenOffline;
  final VoidCallback? onViewInVault;

  const ProgressCard({
    super.key,
    required this.task,
    this.onCancel,
    this.onOpenOffline,
    this.onViewInVault,
  });

  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<ProgressCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(ProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.task.isActive && _timer?.isActive == true) {
      _timer?.cancel();
    } else if (widget.task.isActive && (_timer == null || !_timer!.isActive)) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.task.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsed = DateTime.now().difference(widget.task.startedAt);
          });
        }
      });
    } else if (widget.task.completedAt != null) {
      _elapsed = widget.task.completedAt!.difference(widget.task.startedAt);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _getStatusColor() {
    switch (widget.task.status) {
      case TaskStatus.idle:
        return const Color(0xFF94A3B8);
      case TaskStatus.connecting:
        return const Color(0xFF38BDF8);
      case TaskStatus.downloading:
        return const Color(0xFF6366F1);
      case TaskStatus.converting:
        return const Color(0xFFF59E0B);
      case TaskStatus.syncing:
        return const Color(0xFF06B6D4);
      case TaskStatus.completed:
        return const Color(0xFF10B981);
      case TaskStatus.failed:
      case TaskStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusTitle() {
    switch (widget.task.status) {
      case TaskStatus.idle:
        return 'Idle';
      case TaskStatus.connecting:
        return 'Connecting...';
      case TaskStatus.downloading:
        return 'Mirroring Assets...';
      case TaskStatus.converting:
        return 'Compressing ZIP...';
      case TaskStatus.syncing:
        return 'Transferring to Device...';
      case TaskStatus.completed:
        return 'Ready for Offline Use!';
      case TaskStatus.failed:
        return 'Download Failed';
      case TaskStatus.cancelled:
        return 'Download Cancelled';
    }
  }

  int _getStepIndex() {
    switch (widget.task.status) {
      case TaskStatus.connecting:
        return 0;
      case TaskStatus.downloading:
        return 1;
      case TaskStatus.converting:
        return 2;
      case TaskStatus.syncing:
        return 3;
      case TaskStatus.completed:
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final step = _getStepIndex();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withAlpha(90),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step progress indicator dots
          if (widget.task.isActive || widget.task.isCompleted) ...[
            Row(
              children: [
                _buildStepPill('1. Connect', active: step >= 0, done: step > 0),
                _buildStepDivider(done: step > 0),
                _buildStepPill('2. Mirror', active: step >= 1, done: step > 1),
                _buildStepDivider(done: step > 1),
                _buildStepPill('3. Zip', active: step >= 2, done: step > 2),
                _buildStepDivider(done: step > 2),
                _buildStepPill('4. Sync', active: step >= 3, done: step > 3),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Header Status Badge + Live File Count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.task.isActive) ...[
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _getStatusTitle(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Elapsed time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_elapsed),
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: const Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Target URL
          Text(
            widget.task.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          // Current active file / status details line
          if (widget.task.currentStatusDetails != null || widget.task.activeFileName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.file_download_outlined, size: 14, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.task.activeFileName ?? widget.task.currentStatusDetails ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (widget.task.error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF450A0A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDC2626)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.task.error!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFFECACA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Main Progress Bar & Indicators
          if (widget.task.isActive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.task.status == TaskStatus.syncing
                      ? 'Syncing ZIP: ${(widget.task.zipDownloadPercent ?? 0 * 100).toInt()}%'
                      : 'Files Crawled: ${widget.task.downloadedFilesCount}',
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.task.zipDownloadBytesText != null)
                  Text(
                    widget.task.zipDownloadBytesText!,
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.task.status == TaskStatus.syncing && widget.task.zipDownloadPercent != null
                  ? LinearProgressIndicator(
                      value: widget.task.zipDownloadPercent,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF334155),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                    )
                  : LinearProgressIndicator(
                      minHeight: 8,
                      backgroundColor: const Color(0xFF334155),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
            ),
          ],

          // Completed State Buttons
          if (widget.task.isCompleted) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                value: 1.0,
                minHeight: 6,
                backgroundColor: Color(0xFF334155),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.onOpenOffline != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: widget.onOpenOffline,
                      icon: const Icon(Icons.web_rounded, size: 18),
                      label: const Text('Open Offline Site', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(width: 10),
                if (widget.onViewInVault != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onPressed: widget.onViewInVault,
                    icon: const Icon(Icons.folder_zip_rounded, size: 18),
                    label: const Text('Vault'),
                  ),
              ],
            ),
          ],

          // Cancel button during active download
          if (widget.task.isActive && widget.onCancel != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Color(0xFFF87171)),
                label: Text(
                  'Cancel Process',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFF87171),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepPill(String label, {required bool active, required bool done}) {
    Color bg = const Color(0xFF0F172A);
    Color text = const Color(0xFF64748B);

    if (done) {
      bg = const Color(0xFF065F46);
      text = const Color(0xFF34D399);
    } else if (active) {
      bg = const Color(0xFF1E3A8A);
      text = const Color(0xFF60A5FA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  Widget _buildStepDivider({required bool done}) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: done ? const Color(0xFF10B981) : const Color(0xFF334155),
      ),
    );
  }
}
