import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

class UsbSerialControlScreen extends StatefulWidget {
  const UsbSerialControlScreen({super.key});

  @override
  State<UsbSerialControlScreen> createState() => _UsbSerialControlScreenState();
}

class _UsbSerialControlScreenState extends State<UsbSerialControlScreen> {
  UsbPort? _port;
  List<UsbDevice> _devices = [];
  UsbDevice? _connectedDevice;
  StreamSubscription<Uint8List>? _subscription;
  bool _connected = false;

  // --- STATE FOR UI ---
  // Servo Sliders
  double _servo1Value = 90.0;
  double _servo2Value = 90.0;
  double _servo3Value = 90.0;
  double _servo4Value = 90.0;

  // Serial Console
  final List<String> _consoleLines = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getPorts();
    UsbSerial.usbEventStream?.listen((UsbEvent event) {
      _getPorts();
    });
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  // --- LOGIC METHODS ---

  Future<void> _getPorts() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    setState(() {
      _devices = devices;
    });
  }

  Future<void> _connect(UsbDevice device) async {
    _port = await device.create();
    if (!await (_port!.open())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open port'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _port!.setPortParameters(
      9600,
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    if (kDebugMode) {
      debugPrint("USB port opened. Waiting for handshake from Arduino...");
    }

    // --- HANDSHAKE & STREAM LISTENING ---
    try {
      final handshakeCompleter = Completer<void>();

      _subscription = _port!.inputStream?.listen((Uint8List data) {
        final message = String.fromCharCodes(data).trim();
        if (kDebugMode) {
          debugPrint("Received from Arduino: $message");
        }

        final lines = message.split('\n').where((line) => line.isNotEmpty);

        setState(() {
          _consoleLines.addAll(lines);
          if (_consoleLines.length > 100) {
            _consoleLines.removeRange(0, _consoleLines.length - 100);
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });

        if (lines.contains("HELLO_ARDUINO") &&
            !handshakeCompleter.isCompleted) {
          handshakeCompleter.complete();
        }
      });

      await handshakeCompleter.future.timeout(const Duration(seconds: 3));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Handshake successful! Connected to ${device.productName}!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _connectedDevice = device;
        _connected = true;
      });
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint("Handshake timed out.");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection timed out. Arduino did not respond.'),
          backgroundColor: Colors.red,
        ),
      );
      await _disconnect();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("An error occurred during handshake: $e");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
      await _disconnect();
    }
  }

  Future<void> _disconnect() async {
    await _port?.close();
    _subscription?.cancel();
    setState(() {
      _port = null;
      _connectedDevice = null;
      _connected = false;
    });
  }

  Future<void> _submitAngles() async {
    if (_port == null || !_connected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String command =
        '${_servo1Value.round()},${_servo2Value.round()},${_servo3Value.round()},${_servo4Value.round()}\n';
    await _port!.write(Uint8List.fromList(command.codeUnits));
  }

  void _resetSliders() {
    setState(() {
      _servo1Value = 90.0;
      _servo2Value = 90.0;
      _servo3Value = 90.0;
      _servo4Value = 90.0;
    });
  }

  // --- UI WIDGET BUILDERS ---

  Widget _buildDeviceList() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _getPorts,
          child: const Text("Refresh Device List"),
        ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Connect your phone to the Arduino via a USB OTG adapter.",
            textAlign: TextAlign.center,
          ),
        ),
        if (_devices.isEmpty)
          const Expanded(child: Center(child: Text("No USB devices found."))),
        Expanded(
          child: ListView.builder(
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return ListTile(
                leading: const Icon(Icons.usb),
                title: Text(device.productName ?? 'Unknown Device'),
                subtitle: Text('VID: ${device.vid} PID: ${device.pid}'),
                trailing: ElevatedButton(
                  child: const Text('Connect'),
                  onPressed: () => _connect(device),
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
          Text(
            'Connected to: ${_connectedDevice?.productName ?? "USB Device"}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _disconnect,
            child: const Text('Disconnect'),
          ),
          const Divider(height: 30),
          Text('Servo 1: ${_servo1Value.round()}°'),
          Slider(
            value: _servo1Value,
            min: 0,
            max: 180,
            divisions: 180,
            label: _servo1Value.round().toString(),
            onChanged: (v) => setState(() => _servo1Value = v),
          ),
          Text('Servo 2: ${_servo2Value.round()}°'),
          Slider(
            value: _servo2Value,
            min: 0,
            max: 180,
            divisions: 180,
            label: _servo2Value.round().toString(),
            onChanged: (v) => setState(() => _servo2Value = v),
          ),
          Text('Servo 3: ${_servo3Value.round()}°'),
          Slider(
            value: _servo3Value,
            min: 0,
            max: 180,
            divisions: 180,
            label: _servo3Value.round().toString(),
            onChanged: (v) => setState(() => _servo3Value = v),
          ),
          Text('Servo 4: ${_servo4Value.round()}°'),
          Slider(
            value: _servo4Value,
            min: 0,
            max: 180,
            divisions: 180,
            label: _servo4Value.round().toString(),
            onChanged: (v) => setState(() => _servo4Value = v),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                onPressed: _resetSliders,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Submit'),
                onPressed: _submitAngles,
              ),
            ],
          ),
          _buildSerialConsole(),
        ],
      ),
    );
  }

  Widget _buildSerialConsole() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 20.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blueGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Arduino Serial Console',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.clear_all,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _consoleLines.clear()),
                  tooltip: 'Clear Console',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _consoleLines.length,
              itemBuilder: (context, index) {
                final line = _consoleLines[index];
                Color lineColor = Colors.greenAccent;
                if (line.contains("Error")) {
                  lineColor = Colors.redAccent;
                } else if (line.contains("---")) {
                  lineColor = Colors.cyanAccent;
                }
                return Text(
                  '> $line',
                  style: TextStyle(color: lineColor, fontFamily: 'monospace'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USB Serial Control')),
      body: _connected ? _buildControlUI() : _buildDeviceList(),
    );
  }
}
