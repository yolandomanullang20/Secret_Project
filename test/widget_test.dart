import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bluetooth Scanner',
      home: BluetoothScanner(),
    );
  }
}

class BluetoothScanner extends StatefulWidget {
  const BluetoothScanner({super.key});

  @override
  State<BluetoothScanner> createState() => _BluetoothScannerState();
}

class _BluetoothScannerState extends State<BluetoothScanner> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scanner'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? stopScan : startScan,
            child: Text(isScanning ? 'Stop Scan' : 'Start Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(scanResults[index].device.name),
                  subtitle: Text(scanResults[index].device.id.toString()),
                  onTap: () {
                    // Tambahkan logika untuk menyambungkan ke perangkat Bluetooth di sini
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void startScan() {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    flutterBlue.scanResults.listen((List<ScanResult> results) {
      setState(() {
        scanResults = results;
      });
    });

    flutterBlue.startScan();
  }

  void stopScan() {
    setState(() {
      isScanning = false;
    });

    flutterBlue.stopScan();
  }
}
