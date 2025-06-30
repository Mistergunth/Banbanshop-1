import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../providers/app_provider.dart';

class UserEventsScreen extends StatefulWidget {
  const UserEventsScreen({Key? key}) : super(key: key);

  @override
  _UserEventsScreenState createState() => _UserEventsScreenState();
}

class _UserEventsScreenState extends State<UserEventsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _usersWithEvents = [];
  final TextEditingController _eventController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsersWithEvents();
  }

  Future<void> _loadUsersWithEvents() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final dbHelper = DatabaseHelper();
      final users = await dbHelper.getUsersWithEvents();
      
      setState(() {
        _usersWithEvents = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _addEvent() async {
    if (_eventController.text.isEmpty || _userIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both user ID and event')),
      );
      return;
    }

    try {
      final userId = int.tryParse(_userIdController.text);
      if (userId == null) {
        throw Exception('Invalid user ID');
      }

      final dbHelper = DatabaseHelper();
      await dbHelper.addUserEvent(
        userId: userId,
        content: _eventController.text,
        type: 'user_action',
      );

      // Clear the input field
      _eventController.clear();
      
      // Reload the data
      await _loadUsersWithEvents();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsersWithEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add event form
                if (user?.role == 'admin')
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            labelText: 'User ID',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _eventController,
                          decoration: const InputDecoration(
                            labelText: 'Event Description',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.add_circle),
                          ),
                          onSubmitted: (_) => _addEvent(),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _addEvent,
                          child: const Text('Add Event'),
                        ),
                      ],
                    ),
                  ),
                
                // Users list with events
                Expanded(
                  child: ListView.builder(
                    itemCount: _usersWithEvents.length,
                    itemBuilder: (context, index) {
                      final user = _usersWithEvents[index];
                      final events = (user['events'] as List<dynamic>?) ?? [];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          title: Text(
                            '${user['userName']} (ID: ${user['userId']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${events.length} events'),
                          children: [
                            if (events.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No events found'),
                              )
                            else
                              ...events.map((event) => ListTile(
                                title: Text(event.toString()),
                                leading: const Icon(Icons.event, size: 20),
                              )).toList(),
                          ],
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
