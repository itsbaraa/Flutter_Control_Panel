// lib/screens/wifi_control_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_control_panel/models/pose.dart';

// IMPORTANT: Replace with your PC's local IP address where the PHP server is running.
// Your phone and PC must be on the same Wi-Fi network.
const String serverIp = "ip_address"; // <-- CHANGE THIS
const String baseUrl = "http://$serverIp/servo_api";

class WifiControlScreen extends StatefulWidget {
  const WifiControlScreen({super.key});

  @override
  State<WifiControlScreen> createState() => _WifiControlScreenState();
}

class _WifiControlScreenState extends State<WifiControlScreen> {
  // State for the four sliders
  double _servo1Value = 90.0;
  double _servo2Value = 90.0;
  double _servo3Value = 90.0;
  double _servo4Value = 90.0;
  
  // Future for the list of saved poses
  late Future<List<Pose>> _futurePoses;

  @override
  void initState() {
    super.initState();
    _futurePoses = _fetchPoses();
  }
  
  // Method to refresh the list of poses
  void _refreshPoses() {
    setState(() {
      _futurePoses = _fetchPoses();
    });
  }

  // --- API Communication Methods ---

  Future<void> _submitAngles() async {
    final url = Uri.parse('$baseUrl/update_angles.php');
    try {
      final response = await http.post(url, body: {
        'servo1': _servo1Value.round().toString(),
        'servo2': _servo2Value.round().toString(),
        'servo3': _servo3Value.round().toString(),
        'servo4': _servo4Value.round().toString(),
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Angles submitted successfully!'), backgroundColor: Colors.green,));
      } else {
        throw Exception('Failed to submit angles.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red,));
    }
  }

  Future<void> _savePose() async {
     final url = Uri.parse('$baseUrl/save_pose.php');
    try {
      final response = await http.post(url, body: {
        'servo1': _servo1Value.round().toString(),
        'servo2': _servo2Value.round().toString(),
        'servo3': _servo3Value.round().toString(),
        'servo4': _servo4Value.round().toString(),
      });

      if (response.statusCode == 200 && json.decode(response.body)['status'] == 'success') {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pose saved successfully!'), backgroundColor: Colors.green,));
        _refreshPoses(); // Refresh the list after saving
      } else {
        throw Exception('Failed to save pose.');
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red,));
    }
  }

  Future<List<Pose>> _fetchPoses() async {
    final response = await http.get(Uri.parse('$baseUrl/get_poses.php'));
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Pose.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load poses from server.');
    }
  }

  Future<void> _deletePose(int id) async {
    final url = Uri.parse('$baseUrl/delete_pose.php');
    try {
      final response = await http.post(url, body: {'id': id.toString()});
      if (response.statusCode == 200 && json.decode(response.body)['status'] == 'success') {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pose deleted successfully!'), backgroundColor: Colors.green,));
        _refreshPoses(); // Refresh the list
      } else {
        throw Exception('Failed to delete pose.');
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red,));
    }
  }

  // --- UI Helper Methods ---

  void _resetSliders() {
    setState(() {
      _servo1Value = 90.0;
      _servo2Value = 90.0;
      _servo3Value = 90.0;
      _servo4Value = 90.0;
    });
  }

  void _loadPoseToSliders(Pose pose) {
    setState(() {
      _servo1Value = pose.servo1.toDouble();
      _servo2Value = pose.servo2.toDouble();
      _servo3Value = pose.servo3.toDouble();
      _servo4Value = pose.servo4.toDouble();
    });
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Servo Control'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sliders Section ---
            Text('Servo 1: ${_servo1Value.round()}°'),
            Slider(
              value: _servo1Value,
              min: 0,
              max: 180,
              divisions: 180,
              label: _servo1Value.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _servo1Value = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Text('Servo 2: ${_servo2Value.round()}°'),
            Slider(
              value: _servo2Value,
              min: 0,
              max: 180,
              divisions: 180,
              label: _servo2Value.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _servo2Value = value;
                });
              },
            ),
            const SizedBox(height: 10),
             Text('Servo 3: ${_servo3Value.round()}°'),
            Slider(
              value: _servo3Value,
              min: 0,
              max: 180,
              divisions: 180,
              label: _servo3Value.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _servo3Value = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Text('Servo 4: ${_servo4Value.round()}°'),
            Slider(
              value: _servo4Value,
              min: 0,
              max: 180,
              divisions: 180,
              label: _servo4Value.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _servo4Value = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // --- Control Buttons Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Reset'), onPressed: _resetSliders),
                ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('Save Pose'), onPressed: _savePose),
                ElevatedButton.icon(icon: const Icon(Icons.send), label: const Text('Submit'), onPressed: _submitAngles, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white)),
              ],
            ),
            const Divider(height: 40),

            // --- Saved Poses Section ---
            const Text('Saved Poses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 300, // Constrain the height of the list
              child: FutureBuilder<List<Pose>>(
                future: _futurePoses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No saved poses found.'));
                  }
                  
                  final poses = snapshot.data!;
                  return ListView.builder(
                    itemCount: poses.length,
                    itemBuilder: (context, index) {
                      final pose = poses[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(pose.id.toString())),
                          title: Text('Pose ${pose.id}'),
                          subtitle: Text('${pose.servo1}, ${pose.servo2}, ${pose.servo3}, ${pose.servo4}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow, color: Colors.green),
                                onPressed: () => _loadPoseToSliders(pose),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePose(pose.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}