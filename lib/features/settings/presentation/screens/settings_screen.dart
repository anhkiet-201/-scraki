import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scraki/core/mixins/settings_store_mixin.dart';
import 'package:scraki/features/settings/presentation/widgets/settings_api_key_card.dart';
import 'package:scraki/features/settings/presentation/widgets/settings_error_banner.dart';
import 'package:scraki/features/settings/presentation/widgets/settings_header_bar.dart';
import 'package:scraki/features/settings/presentation/widgets/settings_phone_card.dart';
import 'package:scraki/features/settings/presentation/widgets/settings_save_bar.dart';
import 'package:scraki/features/settings/presentation/widgets/settings_section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SettingsStoreMixin {
  final _apiKeyController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load settings khi màn hình khởi tạo
    settingsStore.loadSettings().then((_) {
      // Cập nhật controllers sau khi load
      _apiKeyController.text = settingsStore.aiApiKey;
      _phoneController.text = settingsStore.posterPhoneNumber;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Observer(
        builder: (_) {
          if (settingsStore.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Header Bar
              const SettingsHeaderBar(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      const SettingsSectionHeader(
                        icon: Icons.settings_suggest_rounded,
                        title: 'Configuration',
                      ),
                      const SizedBox(height: 24),

                      // Cards in horizontal layout with wrap
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          SettingsApiKeyCard(
                            controller: _apiKeyController,
                            onChanged: settingsStore.updateApiKey,
                            onGetApiKey: () {
                              // TODO: Open API key URL
                            },
                          ),
                          SettingsPhoneCard(
                            controller: _phoneController,
                            onChanged: settingsStore.updatePhoneNumber,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Error Message
                      if (settingsStore.errorMessage != null)
                        SettingsErrorBanner(
                          errorMessage: settingsStore.errorMessage!,
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              SettingsSaveBar(
                isLoading: settingsStore.isLoading,
                onSave: () async {
                  await settingsStore.saveSettings();
                  if (settingsStore.errorMessage == null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('Settings saved successfully!'),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
