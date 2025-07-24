import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// These UUIDs must match the ones on your ESP32 code
final Guid serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
final Guid characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

class BluetoothControlScreen extends StatefulWidget {
  const BluetoothControlScreen({super.key});

  @override
  State<BluetoothControlScreen> createState() => _BluetoothControlScreenState();
}

class _BluetoothControlScreenState extends State<BluetoothControlScreen> {
  // Bluetooth State
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _targetCharacteristic;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  // Servo Slider State
  double _servo1Value = 90.0;
  double _servo2Value = 90.0;
  double _servo3Value = 90.0;
  double _servo4Value = 90.0;

  @override
  void initState() {
    super.initState();
  }
  
  void _startScan() {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults = results;
      });
    });
     FlutterBluePlus.isScanning.listen((isScanning) {
        setState(() {
            _isScanning = isScanning;
        });
    });
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _stopScan();
    await device.connect();
    setState(() {
      _connectedDevice = device;
    });
    _discoverServices(device);
  }

  void _disconnectFromDevice() {
    _connectedDevice?.disconnect();
    setState(() {
      _connectedDevice = null;
      _targetCharacteristic = null;
    });
  }
  
  Future<void> _discoverServices(BluetoothDevice device) async {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid == serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == characteristicUuid) {
              setState(() {
                _targetCharacteristic = characteristic;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Servo Controller Found and Ready!'), backgroundColor: Colors.green)
              );
              return;
            }
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Required Servo Service not found on this device.'), backgroundColor: Colors.red)
      );
      _disconnectFromDevice();
  }

  Future<void> _submitAngles() async {
    if (_targetCharacteristic == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to a device.'), backgroundColor: Colors.orange)
      );
      return;
    }

    String command =
        '${_servo1Value.round()},${_servo2Value.round()},${_servo3Value.round()},${_servo4Value.round()}';
    List<int> bytes = utf8.encode(command);
    
    await _targetCharacteristic!.write(bytes, withoutResponse: true);
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Angles Submitted via Bluetooth!'), duration: Duration(seconds: 1),)
      );
  }

  void _resetSliders() {
    setState(() {
      _servo1Value = 90.0;
      _servo2Value = 90.0;
      _servo3Value = 90.0;
      _servo4Value = 90.0;
    });
  }

  // --- UI BUILD METHODS ---
  Widget _buildScanUI() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isScanning ? _stopScan : _startScan,
          child: Text(_isScanning ? 'Stop Scan' : 'Scan for Devices'),
        ),
        if (_isScanning) const LinearProgressIndicator(),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, index) {
              final result = _scanResults[index];
              return ListTile(
                title: Text(result.device.platformName.isEmpty ? 'Unknown Device' : result.device.platformName),
                subtitle: Text(result.device.remoteId.toString()),
                trailing: ElevatedButton(
                  child: const Text('Connect'),
                  onPressed: () => _connectToDevice(result.device),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Connected to: ${_connectedDevice!.platformName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _disconnectFromDevice, child: const Text('Disconnect')),
          const Divider(height: 30),
          // Sliders
          Text('Servo 1: ${_servo1Value.round()}°'),
          Slider(value: _servo1Value, min: 0, max: 180, divisions: 180, label: _servo1Value.round().toString(), onChanged: (v) => setState(() => _servo1Value = v)),
          Text('Servo 2: ${_servo2Value.round()}°'),
          Slider(value: _servo2Value, min: 0, max: 180, divisions: 180, label: _servo2Value.round().toString(), onChanged: (v) => setState(() => _servo2Value = v)),
          Text('Servo 3: ${_servo3Value.round()}°'),
          Slider(value: _servo3Value, min: 0, max: 180, divisions: 180, label: _servo3Value.round().toString(), onChanged: (v) => setState(() => _servo3Value = v)),
          Text('Servo 4: ${_servo4Value.round()}°'),
          Slider(value: _servo4Value, min: 0, max: 180, divisions: 180, label: _servo4Value.round().toString(), onChanged: (v) => setState(() => _servo4Value = v)),
          const SizedBox(height: 20),
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Reset'), onPressed: _resetSliders),
               ElevatedButton.icon(icon: const Icon(Icons.send), label: const Text('Submit'), onPressed: _submitAngles, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Servo Control'),
      ),
      body: _connectedDevice == null ? _buildScanUI() : _buildControlUI(),
    );
  }
}