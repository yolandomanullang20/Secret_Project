import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'bluetooth_provider.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({Key? key}) : super(key: key);

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo? _androidInfo;

  @override
  void initState() {
    super.initState();
    _initDeviceInfo();
  }

  @override
  void dispose() {
    // Clean up
    super.dispose();
  }

  Future<void> _initDeviceInfo() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      setState(() {
        _androidInfo = info;
      });
    }
    _checkPermissions();
  }

  void _checkPermissions() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    if (Platform.isAndroid) {
      _requestPermissions(bluetoothProvider);
    } else {
      bluetoothProvider.startScan();
    }
  }

  void _requestPermissions(BluetoothProvider bluetoothProvider) async {
    int sdk = _androidInfo?.version.sdkInt ?? 0;

    if (sdk >= 31) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ].request();

      if (statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
          statuses[Permission.bluetoothAdvertise] == PermissionStatus.granted &&
          statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {
        bluetoothProvider.startScan();
      } else {
        throw Exception('Bluetooth permission is not granted');
      }
    } else if (sdk >= 23) {
      final PermissionStatus status = await Permission.location.request();

      if (status == PermissionStatus.granted) {
        bluetoothProvider.startScan();
      } else {
        throw Exception('Location permission is not granted');
      }
    } else if (sdk >= 19) {
      final PermissionStatus status = await Permission.bluetooth.request();

      if (status == PermissionStatus.granted) {
        bluetoothProvider.startScan();
      } else {
        throw Exception('Bluetooth permission is not granted');
      }
    } else {
      throw Exception('Unsupported Android SDK version');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, bluetoothProvider, child) {
          return DevicesList(
            devicesList: bluetoothProvider.devicesList,
            isScanning: bluetoothProvider.isScanning,
            startScan: bluetoothProvider.startScan,
            stopScan: bluetoothProvider.stopScan,
            connectToDevice: bluetoothProvider.connectToDevice,
            connectedDevice: bluetoothProvider.connectedDevice,
          );
        },
      ),
    );
  }
}

class DevicesList extends StatelessWidget {
  final List<BluetoothDevice> devicesList;
  final bool isScanning;
  final VoidCallback startScan;
  final VoidCallback stopScan;
  final Function(BluetoothDevice) connectToDevice;
  final BluetoothDevice? connectedDevice;

  const DevicesList({
    Key? key,
    required this.devicesList,
    required this.isScanning,
    required this.startScan,
    required this.stopScan,
    required this.connectToDevice,
    this.connectedDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    return Column(
      children: [
        ElevatedButton(
          onPressed: isScanning ? stopScan : startScan,
          child: Text(isScanning ? 'Stop Scan' : 'Start Scan'),
        ),
        if (connectedDevice != null) ...[
          ListTile(
            title: Text(connectedDevice!.name),
            subtitle: Text(connectedDevice!.id.toString()),
            trailing: ElevatedButton(
              onPressed: () {
                bluetoothProvider.disconnectFromDevice();
              },
              child: const Text('Disconnect'),
            ),
          ),
        ],
        Expanded(
          child: (isScanning && devicesList.isEmpty)
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.separated(
                  itemCount: devicesList.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final BluetoothDevice device = devicesList[index];
                    bool isConnected = device.id == connectedDevice?.id;
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.id.toString()),
                      trailing: Icon(
                        isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                        color: isConnected ? Colors.blue : null,
                      ),
                      onTap: () => connectToDevice(device),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
