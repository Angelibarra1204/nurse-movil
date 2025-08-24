import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/menu_drawer.dart';
import '../widgets/documents_tab.dart';
import 'user_session.dart';
import 'SignosVitales.dart';

class DatosGeneralesPaciente extends StatefulWidget {
  const DatosGeneralesPaciente({Key? key}) : super(key: key);

  @override
  State<DatosGeneralesPaciente> createState() => _DatosGeneralesPacienteState();
}

class _DatosGeneralesPacienteState extends State<DatosGeneralesPaciente> {
  TimeOfDay? horaInicio;
  TimeOfDay? horaFin;
  String turnoDetectado = "";
  bool turnoGuardado = false;
  final TextEditingController nombrePacienteController = TextEditingController();


  Future<void> seleccionarHoraInicio() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora != null) {
      setState(() => horaInicio = hora);
    }
  }

  Future<void> seleccionarHoraFin() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora != null) {
      setState(() => horaFin = hora);
    }
  }

  void calcularTurno() {
    if (horaInicio == null || horaFin == null) {
      setState(() {
        turnoDetectado = "Selecciona ambas horas";
      });
      return;
    }

    final inicioMinutos = horaInicio!.hour * 60 + horaInicio!.minute;
    final finMinutos = horaFin!.hour * 60 + horaFin!.minute;
    int duracion = finMinutos - inicioMinutos;
    if (duracion < 0) duracion += 1440;

    String turno;
    if (duracion > 600) {
      turno = "Doble turno";
    } else if (duracion > 480) {
      turno = "Horas extra";
    } else if (horaInicio!.hour >= 6 && horaInicio!.hour < 14) {
      turno = "Matutino";
    } else if (horaInicio!.hour >= 14 && horaInicio!.hour < 22) {
      turno = "Vespertino";
    } else {
      turno = "Nocturno";
    }

    setState(() {
      turnoDetectado = turno;
    });
  }

  Future<void> guardarTurno() async {
    if (horaInicio == null || horaFin == null) {
      setState(() {
        turnoDetectado = "Selecciona ambas horas";
      });
      return;
    }

    calcularTurno();

    if (nombrePacienteController.text.trim().isEmpty) {
      setState(() {
        turnoDetectado = "Introduzca el nombre del paciente";
      });
      return;
    }

    final now = DateTime.now();
    final fechaInicio = DateTime(now.year, now.month, now.day, horaInicio!.hour, horaInicio!.minute);
    final fechaFin = DateTime(now.year, now.month, now.day, horaFin!.hour, horaFin!.minute);

    int horasExtra = 0;
    if (turnoDetectado == "Horas extra") {
      horasExtra = (fechaFin.difference(fechaInicio).inHours - 8).clamp(1, 24);
    }

    final turno = {
      "Id": "",
      "HoraInicioTurno": horaInicio!.format(context),
      "HoraFinTurno": horaFin!.format(context),
      "Turno": turnoDetectado,
      "Id_Usuario": int.tryParse(UserSession.userId) ?? 0,
      "Id_Enfermero": int.tryParse(UserSession.userId) ?? 0,
      "FechaHoraInicioTurno": fechaInicio.toIso8601String(),
      "FechaHoraFinTurno": fechaFin.toIso8601String(),
      "DobleTurno": turnoDetectado == "Doble turno",
      "HorasExtra": horasExtra,
      "NombrePaciente": nombrePacienteController.text.trim(),
    };

    final response = await http.post(
      Uri.parse('https://nursemovil.bsite.net/api/Turnos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(turno),
    );

    if (response.statusCode == 200) {
      setState(() {
        turnoGuardado = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turno guardado con éxito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar turno: ${response.body}')),
      );
    }
  }

  void reiniciarFormulario() {
    setState(() {
      horaInicio = null;
      horaFin = null;
      turnoDetectado = "";
      turnoGuardado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text("Inicio", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: const MenuDrawer(),
      body: SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card: Turno del Enfermero
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Turno del Enfermero",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: seleccionarHoraInicio,
                    icon: const Icon(Icons.access_time),
                    label: Text(horaInicio == null
                        ? "Seleccionar Hora de Inicio"
                        : "Hora de Inicio: ${horaInicio!.format(context)}"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: seleccionarHoraFin,
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(horaFin == null
                        ? "Seleccionar Hora de Fin"
                        : "Hora de Fin: ${horaFin!.format(context)}"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: nombrePacienteController,
                    decoration: InputDecoration(
                      labelText: "Nombre completo del paciente",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton(
                      onPressed: turnoGuardado ? reiniciarFormulario : guardarTurno,
                      child: Text(turnoGuardado ? "Nuevo Turno" : "Guardar Turno"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      const Icon(Icons.assignment_turned_in, color: Colors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Turno Detectado: $turnoDetectado",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Aquí puedes agregar más Cards, por ejemplo:
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Historial de Bitácoras",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Aquí se mostrarán las bitácoras recientes...",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  // Reemplaza el SizedBox con la sección de búsqueda y tabla:
                  BitacoraSearchSection(), // <-- Nuevo widget con buscador y tabla
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => VitalSignsScreen()),
                ),
                child: const Text('Siguiente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
    );
  }
}
