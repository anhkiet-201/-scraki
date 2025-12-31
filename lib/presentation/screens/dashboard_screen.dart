import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import '../../core/di/injection.dart';
import '../widgets/device/device_grid.dart';
import '../widgets/device/floating_phone_view.dart';
import '../stores/phone_view_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PhoneViewStore _store;

  @override
  void initState() {
    super.initState();
    _store = getIt<PhoneViewStore>();
    _store.loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SCRAKI',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _store.loadDevices(),
            tooltip: 'Refresh Devices',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('TCP Connection Dialog coming soon!'),
                ),
              );
            },
            tooltip: 'Add Device (TCP)',
          ),
        ],
      ),
      body: Observer(
        builder: (_) {
          final futureStatus = _store.loadDevicesFuture?.status;
          final errorMessage = _store.errorMessage;

          if (futureStatus == FutureStatus.pending && _store.devices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null && _store.devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $errorMessage',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _store.loadDevices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _store.loadDevices,
                child: DeviceGrid(
                  devices: _store.devices.toList(),
                  onDisconnect: (device) {
                    _store.disconnect(device.serial);
                  },
                ),
              ),
              // Floating Windows Overlay
              if (_store.isFloatingVisible)
                FloatingPhoneView(
                  key: ValueKey('floating_${_store.floatingSerial}'),
                  serial: _store.floatingSerial!,
                  onClose: () => _store.toggleFloating(null),
                ),
            ],
          );
        },
      ),
    );
  }
}
