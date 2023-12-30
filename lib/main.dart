import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> scanResults = [];
  List<int> rssiValues = [];
  BluetoothDevice? selectedDevice;
  bool isScanning = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
  }

  void toggleState() {
    isScanning = !isScanning;

    if (isScanning) {
      flutterBlue.startScan();
      scan();
    } else {
      flutterBlue.stopScan();
      timer?.cancel();
    }
    setState(() {});
  }

  void scan() async {
    if (isScanning) {
      flutterBlue.scanResults.listen((results) {
        scanResults = results;
        setState(() {});
      });

      timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
        if (isScanning && scanResults.isNotEmpty) {
          for (ScanResult result in scanResults) {
            int rssiValue = await result.rssi;
            updateRssi(result.device.id, rssiValue);
          }
        }
      });
    }
  }

  void updateRssi(DeviceIdentifier deviceId, int rssi) {
    int index = scanResults.indexWhere((result) => result.device.id == deviceId);
    if (index != -1) {
      setState(() {
        rssiValues[index] = rssi;
      });
    }
  }

  void onTap(BluetoothDevice device) {
    if (selectedDevice == null || selectedDevice!.id != device.id) {
      connectToDevice(device);
    } else {
      disconnectDevice(device);
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      selectedDevice = device;
      // Initialize RSSI value for the connected device
      rssiValues.add(-1);
    });
  }

  void disconnectDevice(BluetoothDevice device) async {
    await device.disconnect();
    setState(() {
      selectedDevice = null;
      // Remove RSSI value for the disconnected device
      int index = scanResults.indexWhere((result) => result.device == device);
      if (index != -1) {
        rssiValues.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BLE Scanner with RSSI"),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: toggleState,
            child: Text(isScanning ? "Stop Scan" : "Start Scan"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () => onTap(scanResults[index].device),
                  title: Text(scanResults[index].device.name ?? "Unknown"),
                  subtitle: Text(scanResults[index].device.id.id),
                  trailing: Text(
                    "RSSI: ${rssiValues[index]} dBm",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          if (selectedDevice != null)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Connected Device"),
                  Text("Name: ${selectedDevice!.name ?? 'Unknown'}"),
                  Text("Address: ${selectedDevice!.id.id}"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}