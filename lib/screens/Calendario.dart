import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../widgets/menu_drawer.dart';
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [calendar.CalendarApi.calendarScope]);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Map<String, String>>> _eventsByDay = {};

  calendar.CalendarApi? _calendarApi;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
        if (_currentUser != null) {
          _initializeCalendar();
        }
      });
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _initializeCalendar() async {
    final client = http.Client();
    _calendarApi = calendar.CalendarApi(client);
    await _fetchAndSyncEvents();
  }

  Future<void> _fetchAndSyncEvents() async {
    // 1. Obtener eventos de la API
    final response = await http.get(Uri.parse('https://nursemovil.bsite.net/api/calendarios'));
    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar eventos desde API')));
      return;
    }

    final List<dynamic> apiEvents = json.decode(response.body);
    final Map<DateTime, List<Map<String, String>>> loadedEvents = {};

    // 2. Agrupar eventos por día
    for (var event in apiEvents) {
      DateTime start = DateTime.parse(event['fechaInicio']).toLocal();
      DateTime dayKey = DateTime(start.year, start.month, start.day);

      loadedEvents[dayKey] ??= [];
      loadedEvents[dayKey]!.add({
        'title': event['Titulo'] ?? '',
        'description': event['Descripcion'] ?? '',
        'startTime': start.toString(),
        'endTime': DateTime.parse(event['fechaFin']).toLocal().toString(),
        'apiEventId': event['Id'],
      });
    }

    setState(() {
      _eventsByDay.clear();
      _eventsByDay.addAll(loadedEvents);
    });

    // 3. Sincronizar con Google Calendar
    await _syncEventsToGoogleCalendar(loadedEvents);
  }

 Future<void> _syncEventsToGoogleCalendar(Map<DateTime, List<Map<String, String>>> events) async {
    if (_calendarApi == null) return;

    for (var day in events.keys) {
      for (var event in events[day]!) {
        final calendar.Event newEvent = calendar.Event(
          summary: event['title'] ?? '',
          description: event['description'] ?? '',
          start: calendar.EventDateTime(
            dateTime: DateTime.parse(event['startTime']!).toUtc(),
            timeZone: 'UTC',
          ),
          end: calendar.EventDateTime(
            dateTime: DateTime.parse(event['endTime']!).toUtc(),
            timeZone: 'UTC',
          ),
        );

        try {
          await _calendarApi!.events.insert(newEvent, 'primary');
          print('Evento sincronizado: ${event['title']}');
        } catch (e) {
          print('Error sincronizando evento: $e');
        }
      }
    }
  }

  Widget _buildEventList() {
    DateTime key;
    if (_selectedDay != null) {
      key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    } else {
      // Mostrar próximos eventos si no hay día seleccionado
      key = DateTime.now();
    }

    List<Map<String, String>> events = [];

    if (_selectedDay != null) {
      events = _eventsByDay[key] ?? [];
    } else {
      // Obtener todos los eventos futuros
      events = _eventsByDay.entries
          .where((entry) => entry.key.isAfter(DateTime.now().subtract(const Duration(days: 1))))
          .expand((entry) => entry.value)
          .toList();
    }

    if (events.isEmpty) {
      return const Text('No hay eventos para mostrar');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('${e['startTime']} - ${e['title']}'),
        );
      }).toList(),
    );
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print('Error signing in: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in: $error')),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _currentUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Calendario', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          if (_currentUser == null)
            IconButton(
              icon: const Icon(Icons.login, color: Colors.white),
              onPressed: _handleSignIn,
            ),
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: _handleSignOut,
            ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser != null
                          ? 'Sesión iniciada como: ${_currentUser!.displayName}'
                          : 'No hay usuario autenticado',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildEventList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
