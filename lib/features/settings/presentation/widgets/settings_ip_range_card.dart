import 'package:flutter/material.dart';

/// Card widget for Network IP Range configuration
class SettingsIpRangeCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SettingsIpRangeCard({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 480),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: null,
          boxShadow: isLight 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))] 
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lan_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IP NETWORK RANGE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isLight ? const Color(0xFF1E293B) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dải mạng kết nối tới các Box',
                        style: TextStyle(
                          fontSize: 10,
                          color: isLight ? const Color(0xFF64748B) : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.text,
              style: TextStyle(
                fontSize: 13,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'VD: 10.10.0.0',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isLight ? const Color(0xFF94A3B8) : Colors.white24,
                ),
                prefixIcon: const Icon(
                  Icons.network_ping_rounded,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
                filled: true,
                fillColor: isLight ? Colors.black.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.02),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Định dạng hợp lệ: A.B.0.0 hoặc A.B.x.x (ví dụ: 10.10.0.0)',
                    style: TextStyle(
                      fontSize: 10,
                      color: isLight ? const Color(0xFF64748B) : Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
