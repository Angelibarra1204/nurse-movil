// CalendarScreen con calendario visual y formulario para crear notas/eventos
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error signing in: \$error')));
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

  // Formulario para nueva nota/evento
  Future<void> _showAddNoteDialog() async {
    TextEditingController noteController = TextEditingController();
    TimeOfDay? selectedTime = TimeOfDay.now();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva nota/evento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedDay != null
                  ? 'Día: \${_selectedDay!.toLocal()}'.split(' ')[0]
                  : 'Ningún día seleccionado'),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Descripción/Nota'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Hora:'),
                  const SizedBox(width: 10),
                  Text(selectedTime.format(context)),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        selectedTime = picked;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  )
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Agregar'),
              onPressed: () {
                Navigator.of(context).pop({
                  'desc': noteController.text,
                  'time': selectedTime
                });
              },
            ),
          ],
        );
      },
    ).then((result) {
      if (result != null && result['desc'] != null && result['desc'].trim().isNotEmpty) {
        _addEventToGoogleCalendar(result['desc'], result['time']);
      }
    });
  }

  Future<void> _addEventToGoogleCalendar(String desc, TimeOfDay? time) async {
    if (_currentUser != null && _selectedDay != null) {
      final authHeaders = await _currentUser!.authHeaders;
      final client = http.Client();
      final calendarApi = calendar.CalendarApi(client);

      DateTime startDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        time?.hour ?? 8,
        time?.minute ?? 0,
      );
      DateTime endDateTime = startDateTime.add(const Duration(hours: 1));

      final event = calendar.Event(
        summary: desc,
        start: calendar.EventDateTime(
          dateTime: startDateTime,
          timeZone: 'GMT-05:00',
        ),
        end: calendar.EventDateTime(
          dateTime: endDateTime,
          timeZone: 'GMT-05:00',
        ),
      );

      try {
        await calendarApi.events.insert(event, "primary");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Evento añadido al calendario de Google")),
        );
  await _fetchGoogleCalendarEvents();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir evento: \$e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión y selecciona un día primero')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          if (_currentUser == null)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _handleSignIn,
            ),
          if (_currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _googleSignIn.signOut();
                setState(() {
                  _currentUser = null;
                  _eventMap.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
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
            eventLoader: (day) {
              return _eventMap[DateTime(day.year, day.month, day.day)] ?? [];
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.note_add),
            label: const Text('Agregar nota/evento'),
            onPressed: _selectedDay != null && _currentUser != null
                ? _showAddNoteDialog
                : null,
          ),
          if (_selectedDay != null && _eventMap[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] != null)
            ..._eventMap[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]!.map((e) => ListTile(
              leading: const Icon(Icons.event),
              title: Text(e),
            ))
        ],
      ),
    );
  }
}
