import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Card widget for Max Devices configuration
class SettingsMaxDevicesCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SettingsMaxDevicesCard({
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
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.devices_other_rounded,
                    size: 18,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MAX DEVICE COUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isLight ? const Color(0xFF1E293B) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Số lượng thiết bị tối đa quét kết nối',
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
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 13,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'VD: 100',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isLight ? const Color(0xFF94A3B8) : Colors.white24,
                ),
                prefixIcon: const Icon(
                  Icons.screenshot_monitor_rounded,
                  color: Color(0xFF8B5CF6),
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
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
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
                    'Mặc định là 100. Nên cấu hình phù hợp với số lượng Box thực tế.',
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
