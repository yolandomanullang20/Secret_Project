import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/bluetooth_page.dart';
import 'bluetooth_provider.dart';
import 'excel.dart';
import 'Date.dart';

int largeFishCount = 0;
int veryLargeFishCount = 0;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BluetoothProvider(),
      child: MaterialApp(
        title: 'My App',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.lightGreen[100],
        ),
        home: const MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      Image.asset(
        'assets/lele.png',
        height: 200,
        width: 200,
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BluetoothPage(),
            ),
          );
        },
        child: const Text('Go to Bluetooth Page'),
      ),
      const SizedBox(height: 20),
      const FishCounter(), // Use widget from the FishCounter class
      const SizedBox(height: 20),
      const DateTimeDisplay(), // Display Date and Time
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          final bluetoothProvider =
              Provider.of<BluetoothProvider>(context, listen: false);
          bluetoothProvider.sendResetMessageToBluetooth();
        },
        child: const Text('Reset Device'),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

//sistem counting ikan lele
class FishCounter extends StatefulWidget {
  const FishCounter({super.key});

  @override
  State<FishCounter> createState() => _FishCounterState();
}

class _FishCounterState extends State<FishCounter> {
  int largeFishCount = 0;
  int veryLargeFishCount = 0;
  Map fishData = {};

  @override
  void initState() {
    super.initState();
    // Listen to updates from BluetoothProvider
    final bluetoothProvider =
        Provider.of<BluetoothProvider>(context, listen: false);
    bluetoothProvider.addListener(_updateFishCountsFromBluetooth);
  }

  @override
  void dispose() {
    final bluetoothProvider =
        Provider.of<BluetoothProvider>(context, listen: false);
    bluetoothProvider.removeListener(_updateFishCountsFromBluetooth);
    super.dispose();
  }

  void _updateFishCountsFromBluetooth() {
    final bluetoothProvider =
        Provider.of<BluetoothProvider>(context, listen: false);
    setState(() {
      largeFishCount = bluetoothProvider.largeFishCounter;
      veryLargeFishCount = bluetoothProvider.veryLargeFishCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider =
        Provider.of<BluetoothProvider>(context, listen: false);

    return StreamBuilder<List<int>>(
      stream: bluetoothProvider.dataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Waiting for data...',
            style: Theme.of(context).textTheme.titleLarge,
          );
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: Theme.of(context).textTheme.titleLarge,
          );
        } else if (!snapshot.hasData) {
          return Text(
            'No data received',
            style: Theme.of(context).textTheme.titleLarge,
          );
        } else {
          // Process the received data
          List<int> data = snapshot.data!;
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
            largeFishCount = largeFish;
            veryLargeFishCount = veryLargeFish;
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Ikan Berukuran Besar: $largeFishCount',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Ikan Berukuran Sangat Besar: $veryLargeFishCount',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  fishData = {
                    'large_fish': largeFishCount.toString(),
                    'very_large_fish': veryLargeFishCount.toString(),
                  };

                  ExcelHelper().exportToExcel(
                    context,
                    fishData,
                  ); // Call function to export to Excel
                },
                child: const Text('Export to Excel'),
              ),
            ],
          );
        }
      },
    );
  }
}
