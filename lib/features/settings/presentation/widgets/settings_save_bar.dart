import 'package:flutter/material.dart';

/// Bottom action bar with save button for Settings screen
class SettingsSaveBar extends StatelessWidget {
  final VoidCallback? onSave;
  final bool isLoading;

  const SettingsSaveBar({
    super.key,
    required this.onSave,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.black.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(
            color: isLight
                ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                : Colors.white10,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info text
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Text(
                  'Dữ liệu sẽ được lưu trữ cục bộ và đồng bộ hóa',
                  style: TextStyle(
                    fontSize: 11,
                    color: isLight ? const Color(0xFF64748B) : Colors.white38,
                  ),
                ),
              ],
            ),
          ),

          // Save Button
          ElevatedButton.icon(
            onPressed: isLoading ? null : onSave,
            icon: isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              'LƯU CẤU HÌNH',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 11),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
