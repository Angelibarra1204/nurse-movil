import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({Key? key}) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Map<String, String>>> _localEvents = {};

  calendar.CalendarApi? _calendarApi;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
        if (_currentUser != null) {
          _getGoogleCalendarApi();
        }
      });
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $error')),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() => _currentUser = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
  }

  Future<void> _getGoogleCalendarApi() async {
    if (_currentUser == null) return;
    final auth = await _currentUser!.authentication;
    final client = http.Client();
    _calendarApi = calendar.CalendarApi(client);
    _loadGoogleCalendarEvents();
  }

  Future<void> _loadGoogleCalendarEvents() async {
    if (_calendarApi == null || _selectedDay == null) return;

    DateTime startDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    DateTime endDate = startDate.add(const Duration(days: 1));

    final events = await _calendarApi!.events.list(
      'primary',
      timeMin: startDate.toUtc(),
      timeMax: endDate.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );

    setState(() {
      _localEvents[_selectedDay!] = events.items?.map((e) {
            return {
              'title': e.summary ?? '',
              'startTime': e.start?.dateTime?.toLocal().toString() ?? '',
              'endTime': e.end?.dateTime?.toLocal().toString() ?? '',
              'googleEventId': e.id ?? '',
            };
          }).toList() ??
          [];
    });
  }

  Future<void> _showAddEventDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo evento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Inicio:'),
                  const SizedBox(width: 10),
                  Text(startTime.format(context)),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime);
                      if (picked != null) {
                        startTime = picked;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Fin:'),
                  const SizedBox(width: 10),
                  Text(endTime.format(context)),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: endTime);
                      if (picked != null) {
                        endTime = picked;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'title': titleController.text.trim(),
                'description': descriptionController.text.trim(),
                'startTime': startTime,
                'endTime': endTime,
              });
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result != null && _selectedDay != null) {
      await _addEvent(result);
    }
  }

Future<void> _addEvent(Map<String, dynamic> eventData) async {
  final title = eventData['title'] as String;
  final description = eventData['description'] as String;
  final TimeOfDay startTime = eventData['startTime'] as TimeOfDay;
  final TimeOfDay endTime = eventData['endTime'] as TimeOfDay;

  final startDateTime = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, startTime.hour, startTime.minute);
  final endDateTime = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, endTime.hour, endTime.minute);

  // Guardar evento en API propia
  final apiEvent = {
    "Id": "",
    "Titulo": title,
    "Descripcion": description,
    "FechaInicio": startDateTime.toIso8601String(),
    "FechaFin": endDateTime.toIso8601String(),
  };

  final apiResponse = await http.post(
    Uri.parse('https://nursemovil.bsite.net/api/Calendarios'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(apiEvent),
  );

  if (apiResponse.statusCode == 200 || apiResponse.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento guardado en la API')));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar evento en API: ${apiResponse.body}')));
    return; // No intentamos agregar a Google si falla en API
  }

  // Si hay sesión en Google, sincronizar con Google Calendar
  if (_currentUser != null) {
    final auth = await _currentUser!.authentication;
    final accessToken = auth.accessToken;

    final client = http.Client();

    final event = calendar.Event(
      summary: title,
      description: description,
      start: calendar.EventDateTime(dateTime: startDateTime.toUtc(), timeZone: 'UTC'),
      end: calendar.EventDateTime(dateTime: endDateTime.toUtc(), timeZone: 'UTC'),
    );

    final response = await client.post(
      Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary/events'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(event.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento sincronizado con Google Calendar')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al sincronizar con Google: ${response.body}')));
    }
  }

  _loadEvents(); // refrescar vista
}


  Widget _buildEventList() {
    if (_selectedDay == null) return const Text('Selecciona un día');

    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final events = _localEvents[key] ?? [];

    if (events.isEmpty) return const Text('No hay eventos para este día');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Eventos del día:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...events.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${e['startTime']} - ${e['endTime']} | ${e['title']}'),
            )),
      ],
    );
  }

Future<void> _loadEvents() async {
  if (_selectedDay == null) return;

  final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

  List<Map<String, String>> events = [];

  // Cargar eventos desde tu API
  final apiResponse = await http.get(
    Uri.parse('https://nursemovil.bsite.net/api/Calendarios?fecha=${_selectedDay!.toIso8601String()}'),
  );

  if (apiResponse.statusCode == 200) {
    final List<dynamic> apiEvents = json.decode(apiResponse.body);
    events.addAll(apiEvents.map((e) => <String, String>{
      'title': e['Titulo']?.toString() ?? '',
      'startTime': e['FechaInicio']?.toString() ?? '',
      'endTime': e['FechaFin']?.toString() ?? '',
    }).where((event) {
      // Filtrar solo eventos del día seleccionado:
      DateTime start = DateTime.parse(event['startTime']!);
      return start.year == key.year && start.month == key.month && start.day == key.day;
    }).toList());
  }

  // Si hay sesión en Google, carga también de Google Calendar
  if (_calendarApi != null) {
    DateTime startDate = DateTime(key.year, key.month, key.day);
    DateTime endDate = startDate.add(const Duration(days: 1));

    final googleEvents = await _calendarApi!.events.list(
      'primary',
      timeMin: startDate.toUtc(),
      timeMax: endDate.toUtc(),
      singleEvents: true,
      orderBy: 'startTime',
    );

    events.addAll(googleEvents.items?.map((e) => <String, String>{
      'title': e.summary ?? '',
      'startTime': e.start?.dateTime?.toLocal().toString() ?? '',
      'endTime': e.end?.dateTime?.toLocal().toString() ?? '',
    }).where((event) {
      // Igual filtro por seguridad
      DateTime start = DateTime.parse(event['startTime']!);
      return start.year == key.year && start.month == key.month && start.day == key.day;
    }).toList() ?? []);
  }

  setState(() {
    _localEvents[key] = events;
  });
}


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currentUser != null
                        ? 'Sesión iniciada como: ${_currentUser!.displayName}'
                        : 'No autenticado en Google',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.login),
                  onPressed: _handleSignIn,
                  tooltip: 'Iniciar sesión Google',
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _handleSignOut,
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
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
  _loadEvents(); // <--- Cambia aquí
},
            ),
            const SizedBox(height: 12),
           ElevatedButton.icon(
  icon: const Icon(Icons.note_add),
  label: const Text('Agregar evento'),
  onPressed: _selectedDay != null ? _showAddEventDialog : null,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    minimumSize: const Size.fromHeight(45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
),

            const SizedBox(height: 16),
            _buildEventList(),
          ],
        ),
      ),
    );
  }
}
