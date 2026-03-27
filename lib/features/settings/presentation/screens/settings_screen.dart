import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import '../stores/settings_store.dart';
import '../stores/settings_email_store.dart';
import '../widgets/settings_api_key_card.dart';
import '../widgets/settings_collection_card.dart';
import '../widgets/settings_email_credential_card.dart';
import '../widgets/settings_error_banner.dart';
import '../widgets/settings_header_bar.dart';
import '../widgets/settings_phone_card.dart';
import '../widgets/settings_save_bar.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_help_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settingsStore = GetIt.I<SettingsStore>();
  final emailStore = GetIt.I<SettingsEmailStore>();
  final _apiKeyController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load both stores
    settingsStore.loadSettings().then((_) {
      _apiKeyController.text = settingsStore.aiApiKey;
      _phoneController.text = settingsStore.posterPhoneNumber;
    });
    emailStore.loadCredentials();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      body: Observer(
        builder: (_) {
          final isLoading = settingsStore.isLoading || emailStore.isLoading;
          final errorMessage = settingsStore.errorMessage ?? emailStore.errorMessage;

          if (isLoading && settingsStore.settings == null && emailStore.rawCredentials.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // Mesh Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLight 
                          ? [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)]
                          : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                    ),
                  ),
                ),
              ),
              if (isLight) ...[
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  left: -50,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],

              // Main Layout
              Row(
                children: [
                  // Sidebar
                  _buildSidebar(isLight),

                  // Content Area
                  Expanded(
                    child: Column(
                      children: [
                        const SettingsHeaderBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1400),
                                child: Column(
                                  children: [
                                    if (_selectedCategoryIndex == 0)
                                      _buildGeneralSettings(isLight)
                                    else
                                      _buildEmailSettings(isLight),
                                    
                                    if (errorMessage != null) ...[
                                      const SizedBox(height: 32),
                                      SettingsErrorBanner(errorMessage: errorMessage),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SettingsSaveBar(
                          isLoading: isLoading,
                          onSave: () async {
                            if (_selectedCategoryIndex == 0) {
                              await settingsStore.saveSettings();
                            } else {
                              await emailStore.saveCredentials();
                            }
                            
                            if (errorMessage == null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                      SizedBox(width: 12),
                                      Text('Đã lưu cấu hình thành công!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(bool isLight) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.black.withValues(alpha: 0.2),
        border: Border(
          right: BorderSide(
            color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildSidebarItem(0, Icons.settings_suggest_rounded, 'Chung', isLight),
          const SizedBox(height: 16),
          _buildSidebarItem(1, Icons.mark_email_read_outlined, 'Email', isLight),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Icon(
              Icons.help_outline_rounded,
              color: isLight ? const Color(0xFF64748B) : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, bool isLight) {
    final isSelected = _selectedCategoryIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: 80,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? const Color(0xFF6366F1) 
                  : (isLight ? const Color(0xFF64748B) : Colors.white38),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                color: isSelected 
                    ? const Color(0xFF6366F1) 
                    : (isLight ? const Color(0xFF64748B) : Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.settings_suggest_rounded,
          title: 'CONFIGURATION',
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Main Cards
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SettingsApiKeyCard(
                    controller: _apiKeyController,
                    onChanged: settingsStore.updateApiKey,
                    onGetApiKey: () { /* TODO */ },
                  ),
                  const SizedBox(height: 24),
                  SettingsPhoneCard(
                    controller: _phoneController,
                    onChanged: settingsStore.updatePhoneNumber,
                  ),
                  const SizedBox(height: 24),
                  SettingsCollectionCard(
                    selectedCollection: settingsStore.deviceGroupCollection,
                    onChanged: settingsStore.updateDeviceGroupCollection,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right Column: Help Panels
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  const SettingsHelpPanel(
                    title: 'Tại sao cần API Key?',
                    description: 'API Key cho phép ứng dụng kết nối với AI Model để tạo nội dung script video tự động. Bạn nên bảo mật khóa này.',
                  ),
                  const SizedBox(height: 16),
                  const SettingsHelpPanel(
                    title: 'Về Firestore Collection',
                    description: 'Việc chọn đúng collection giúp đồng bộ hóa danh sách thiết bị chính xác giữa các tài khoản khác nhau.',
                    accentColor: Color(0xFF10B981),
                    icon: Icons.storage_rounded,
                  ),
                  const SizedBox(height: 16),
                  const SettingsHelpPanel(
                    title: 'Số điện thoại',
                    description: 'Số điện thoại này sẽ được hiển thị công khai trên các poster hoặc video khi xuất bản.',
                    accentColor: Color(0xFFF59E0B),
                    icon: Icons.phone_android_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailSettings(bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(
          icon: Icons.mark_email_read_outlined,
          title: 'EMAIL AUTOMATION',
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Data Card
            const Expanded(
              flex: 3,
              child: SettingsEmailCredentialCard(),
            ),
            const SizedBox(width: 32),
            // Help Panel
            const Expanded(
              flex: 1,
              child: SettingsHelpPanel(
                title: 'Hướng dẫn định dạng',
                description: 'Nhập dữ liệu theo định dạng:\nEmail|Mật khẩu|Mã Token|Tên nhóm\n\nMỗi tài khoản trên một dòng. Hệ thống sẽ tự động tô màu và đánh số để bạn dễ quản lý.',
                accentColor: Color(0xFF6366F1),
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
