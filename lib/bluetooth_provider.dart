import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';

class BluetoothProvider with ChangeNotifier {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  bool isScanning = false;
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> devicesList = [];
  StreamSubscription<List<int>>? _dataSubscription;
  StreamController<List<int>> _dataStreamController =
      StreamController.broadcast();

  BluetoothDevice? get connectedDevice => _connectedDevice;

  int _largeFishCounter = 0;
  int _veryLargeFishCount = 0;

  int get largeFishCounter => _largeFishCounter;
  int get veryLargeFishCount => _veryLargeFishCount;

  Stream<List<int>> get dataStream => _dataStreamController.stream;

  void startScan() {
    isScanning = true;
    notifyListeners();
    flutterBlue.startScan(timeout: const Duration(seconds: 5)).then((_) {
      flutterBlue.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!devicesList.contains(result.device)) {
            devicesList.add(result.device);
            notifyListeners();
          }
        }
      });
    });
  }

  void stopScan() {
    isScanning = false;
    flutterBlue.stopScan();
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    stopScan();
    await device.connect(autoConnect: false);
    _connectedDevice = device;
    notifyListeners();
    _startListeningToData();
  }

  Future<void> disconnectFromDevice() async {
    if (_connectedDevice != null) {
      try {
        print(
            'Attempting to disconnect from device: ${_connectedDevice!.name}');
        await _connectedDevice!.disconnect();
        print('Successfully disconnected from device');
      } catch (e) {
        print('Error disconnecting from device: $e');
      } finally {
        _connectedDevice = null;
        _dataSubscription?.cancel();
        _dataSubscription = null;
        _dataStreamController.close();
        _dataStreamController = StreamController.broadcast();
        notifyListeners();
      }
    } else {
      print('No device to disconnect');
    }
  }

  void _startListeningToData() {
    _connectedDevice?.discoverServices().then((services) {
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify) {
            characteristic.setNotifyValue(true);
            _dataSubscription = characteristic.value.listen((data) {
              _handleData(data);
              _dataStreamController.add(data); // Add data to stream
            });
          }
        }
      }
    });
  }

  void receiveData(List<int> data) {
    _handleData(data);
    _dataStreamController.add(data); // Add data to stream
  }

  void _handleData(List<int> data) {
    String dataString =
        data.map((e) => e.toRadixString(16).padLeft(2, '0')).join('-');
    List<String> parts = dataString.split('-');

    int? largeFish;
    int? veryLargeFish;

    if (parts.length >= 9) {
      largeFish = int.tryParse(parts[4], radix: 16);
      veryLargeFish = int.tryParse(parts[7], radix: 16);
    }

    if (largeFish != null && veryLargeFish != null) {
      _updateFishCount(largeFish, veryLargeFish);
    }
  }

  void _updateFishCount(int largeFish, int veryLargeFish) {
    _largeFishCounter = largeFish;
    _veryLargeFishCount = veryLargeFish;
    notifyListeners();
  }

  // Fungsi untuk mengirim pesan ke Bluetooth
  void sendResetMessageToBluetooth() async {
    _sendMessageToBluetooth("reset\r\n");
  }

  void _sendMessageToBluetooth(String message) async {
    if (_connectedDevice != null) {
      var services = await _connectedDevice!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(utf8.encode(message));
          }
        }
      }
    }
  }
}
