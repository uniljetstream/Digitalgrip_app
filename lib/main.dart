import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const IoTLampApp());
}

class IoTLampApp extends StatelessWidget {
  const IoTLampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Lamp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const IoTLampPage(),
    );
  }
}

class IoTLampPage extends StatefulWidget {
  const IoTLampPage({super.key});

  @override
  _IoTLampPageState createState() => _IoTLampPageState();
}

class _IoTLampPageState extends State<IoTLampPage> {
  final TextEditingController _thingNameController = TextEditingController();
  String _status = "Pending Check";
  bool _isLoading = false;

  final String _apiUrl =
      "APIURL";

  final List<String> _registeredThings = [];  // List to store registered things
  final Map<String, String> _thingStatus = {}; // Map to store the status of registered things

  Future<void> _checkStatus(String thingName) async {
    setState(() {
      _isLoading = true;
    });

    if (thingName.isEmpty) {
      _showError("Please enter a valid Thing Name.");
      return;
    }

    try {
      final response = await http.get(Uri.parse("$_apiUrl?thingname=$thingName"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _thingStatus[thingName] = data['status'] ?? "Unknown";
        });
      } else {
        _showError("Failed to fetch status.");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(String thingName) async {
    setState(() {
      _isLoading = true;
    });

    if (thingName.isEmpty) {
      _showError("Please enter a valid Thing Name.");
      return;
    }

    String action = _thingStatus[thingName] == "It's Off" ? "on" : "off";

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': action,
          'thingname': thingName,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _thingStatus[thingName] = action == "on" ? "It's On" : "It's Off";
        });
      } else {
        _showError("Failed to toggle status.");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeThing(String thingName) async {
    setState(() {
      _registeredThings.remove(thingName);
      _thingStatus.remove(thingName);
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thing "$thingName" removed successfully')));
  }

  void _registerThing() {
    String thingName = _thingNameController.text.trim();
    if (thingName.isEmpty) {
      _showError("Please enter a Thing Name.");
      return;
    }

    setState(() {
      _registeredThings.add(thingName);
      _thingStatus[thingName] = "It's Off";  // Default status is off
    });

    _thingNameController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thing "$thingName" registered successfully')));
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IoT Lamp'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Register'),
              Tab(text: 'Control'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RegisterPage(
              thingNameController: _thingNameController,
              isLoading: _isLoading,
              registerThing: _registerThing,
            ),
            ControllPage(
              registeredThings: _registeredThings,
              thingStatus: _thingStatus,
              isLoading: _isLoading,
              checkStatus: _checkStatus,
              toggleStatus: _toggleStatus,
              removeThing: _removeThing,
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatelessWidget {
  final TextEditingController thingNameController;
  final bool isLoading;
  final Function registerThing;

  const RegisterPage({
    Key? key,
    required this.thingNameController,
    required this.isLoading,
    required this.registerThing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Enter Thing Name to Register:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: thingNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Thing Name',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : () => registerThing(),
            child: isLoading
                ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                : const Text("Register"),
          ),
        ],
      ),
    );
  }
}

class ControllPage extends StatelessWidget {
  final List<String> registeredThings;
  final Map<String, String> thingStatus;
  final bool isLoading;
  final Function checkStatus;
  final Function toggleStatus;
  final Function removeThing;

  const ControllPage({
    Key? key,
    required this.registeredThings,
    required this.thingStatus,
    required this.isLoading,
    required this.checkStatus,
    required this.toggleStatus,
    required this.removeThing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Control Registered Things:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          registeredThings.isEmpty
              ? const Text("No registered things yet.")
              : Expanded(
            child: ListView.builder(
              itemCount: registeredThings.length,
              itemBuilder: (context, index) {
                String thingName = registeredThings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(thingName),
                    subtitle: Text("Status: ${thingStatus[thingName]}"),
                    trailing: isLoading
                        ? const CircularProgressIndicator()
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => checkStatus(thingName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.power_settings_new),
                          onPressed: () => toggleStatus(thingName),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => removeThing(thingName),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
