import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scraki/features/script/presentation/stores/terminal_store.dart';

class ScriptHeader extends StatelessWidget {
  final TerminalStore store;

  const ScriptHeader({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Automation Control',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A), // Slate 900
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Quản lý và thực thi lệnh hàng loạt',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF64748B), // Slate 500
                ),
              ),
            ],
          ),
          // Status Badge
          Observer(
            builder: (_) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: store.isExecuting
                    ? const Color(0xFFFEF3F2) // Red 50
                    : const Color(0xFFECFDF5), // Emerald 50
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: store.isExecuting
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFD1FAE5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: store.isExecuting
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    store.isExecuting ? 'Đang thực thi' : 'Sẵn sàng',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: store.isExecuting
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
