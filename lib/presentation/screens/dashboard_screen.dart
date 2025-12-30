import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobx/mobx.dart';
import '../../core/di/injection.dart';
import '../components/organisms/device_grid.dart';
import '../stores/device_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DeviceStore _store;

  @override
  void initState() {
    super.initState();
    _store = getIt<DeviceStore>();
    _store.loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scraki',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _store.loadDevices(),
          ),
          IconButton(
            icon: const Icon(Icons.add), // Add TCP
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('TCP Connection Dialog coming soon!'),
                ),
              );
            },
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

          return RefreshIndicator(
            onRefresh: _store.loadDevices,
            child: DeviceGrid(
              devices: _store.devices.toList(),
              onDisconnect: (device) {
                _store.disconnect(device.serial);
              },
            ),
          );
        },
      ),
    );
  }
}
