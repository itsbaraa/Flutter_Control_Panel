// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_control_panel/screens/bluetooth_control_screen.dart';
import 'package:flutter_control_panel/screens/usb_serial_control_screen.dart';
import 'package:flutter_control_panel/screens/wifi_control_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Control Mode'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.wifi),
                label: const Text('Wi-Fi Control'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WifiControlScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth),
                label: const Text('Bluetooth Control'),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BluetoothControlScreen()),
                  );
                },
                 style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.usb),
                label: const Text('USB Serial Control'),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UsbSerialControlScreen()),
                  );
                },
                 style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}