import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TerminalLogView extends StatefulWidget {
  final List<String> logs;
  final bool isRunning;
  final VoidCallback? onClear;

  const TerminalLogView({
    super.key,
    required this.logs,
    this.isRunning = false,
    this.onClear,
  });

  @override
  State<TerminalLogView> createState() => _TerminalLogViewState();
}

class _TerminalLogViewState extends State<TerminalLogView> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void didUpdateWidget(TerminalLogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyAllLogs() {
    final allText = widget.logs.join('\n');
    Clipboard.setData(ClipboardData(text: allText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getLogColor(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('200 ok') || lower.contains('completed') || lower.contains('saved')) {
      return const Color(0xFF4ADE80); // Neon Green
    } else if (lower.contains('error') || lower.contains('failed') || lower.contains('refused')) {
      return const Color(0xFFF87171); // Soft Red
    } else if (lower.contains('converting') || lower.contains('compressing') || lower.contains('awaiting')) {
      return const Color(0xFFFBBF24); // Warm Amber
    } else if (lower.contains('connecting') || lower.contains('resolving') || lower.contains('request')) {
      return const Color(0xFF38BDF8); // Sky Blue
    }
    return const Color(0xFFE2E8F0); // Light gray
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                // Traffic light dots
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'wget-stream.log',
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                if (widget.isRunning) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF94A3B8)),
                  tooltip: 'Copy Logs',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.logs.isNotEmpty ? _copyAllLogs : null,
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    _autoScroll ? Icons.arrow_downward_rounded : Icons.pause_rounded,
                    size: 16,
                    color: _autoScroll ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                  ),
                  tooltip: _autoScroll ? 'Auto-scroll ON' : 'Auto-scroll PAUSED',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _autoScroll = !_autoScroll;
                    });
                  },
                ),
              ],
            ),
          ),

          // Terminal Output Area
          Expanded(
            child: widget.logs.isEmpty
                ? Center(
                    child: Text(
                      'Ready. Enter a website URL above to stream download.',
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.logs.length,
                    itemBuilder: (context, index) {
                      final line = widget.logs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: Text(
                          line,
                          style: GoogleFonts.firaCode(
                            fontSize: 11.5,
                            height: 1.4,
                            color: _getLogColor(line),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
