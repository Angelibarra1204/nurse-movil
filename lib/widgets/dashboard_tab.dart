import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  static const verdePrincipal = Color(0xFF22543D);

  Map<String, dynamic>? data;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final responseSignos = await http.get(Uri.parse('https://nursemovil.bsite.net/api/Signos'));
      final responseUsuarios = await http.get(Uri.parse('https://nursemovil.bsite.net/api/Usuarios'));

      if (responseSignos.statusCode != 200 || responseUsuarios.statusCode != 200) {
        throw Exception('Error en las respuestas del servidor');
      }

      final signos = json.decode(responseSignos.body) as List<dynamic>;
      final usuarios = json.decode(responseUsuarios.body) as List<dynamic>;

      if (signos.isEmpty) {
        setState(() {
          data = null;
          isLoading = false;
        });
        return;
      }

      signos.sort((a, b) => DateTime.parse(b['FechaHora']).compareTo(DateTime.parse(a['FechaHora'])));
      final ultimoSigno = signos.first;
     final usuarioId = ultimoSigno['Id_Usuario'];

    final usuario = usuarios.firstWhere(
      (u) => u['Id_Usuario'] == usuarioId,
      orElse: () => null,
    );

    setState(() {
      data = {
        'signo': ultimoSigno,
        'enfermero': usuario != null && usuario['Tipo_usuario'] == 'Enfermero' ? usuario : null,
      };
      isLoading = false;
    });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _formatearFecha(String fechaISO) {
    final fecha = DateTime.parse(fechaISO);
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    final dia = fecha.day.toString().padLeft(2, '0');
    final mesNombre = meses[fecha.month - 1];
    final anio = fecha.year;

    final hora = fecha.hour > 12 ? fecha.hour - 12 : (fecha.hour == 0 ? 12 : fecha.hour);
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final ampm = fecha.hour >= 12 ? 'PM' : 'AM';

    return '$dia $mesNombre $anio, $hora:$minuto $ampm';
  }

  Widget _datoVital(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          const Spacer(),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: verdePrincipal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
  child: Container(
    key: const ValueKey('dashboard'),
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🩺 Signos Vitales Recientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: verdePrincipal,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: verdePrincipal),
              tooltip: 'Actualizar',
              onPressed: _fetchData,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: verdePrincipal))
        else if (error != null)
          Center(child: Text('Error: $error', style: const TextStyle(color: verdePrincipal)))
        else if (data == null || data!['signo'] == null)
          const Center(child: Text('No se encontró ningún signo registrado.', style: TextStyle(color: verdePrincipal)))
        else
          Card(
            color: verdePrincipal.withOpacity(0.1),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: verdePrincipal),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha: ${_formatearFecha(data!['signo']['FechaHora']).split(',')[0]}, ${data!['signo']['Temperatura'][0]['Hora']}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: verdePrincipal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28, thickness: 1),
                  _datoVital('🌡️ Temperatura', '${data!['signo']['Temperatura'][0]['Numero']} °C'),
                  _datoVital('💓 Presión arterial', '${data!['signo']['PresionArterial'][0]['Numero']} mmHg'),
                  _datoVital('❤️‍🔥 Frecuencia cardiaca', '${data!['signo']['FrecuenciaCardiaca'][0]['Numero']} bpm'),
                  _datoVital('🫁 Saturación O₂', '${data!['signo']['SaturacionO2'][0]['Numero']} %'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, color: verdePrincipal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enfermero responsable: ${data!['enfermero'] != null ? data!['enfermero']['Nombre'] + ' ' + data!['enfermero']['Apellidos'] : 'No identificado'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: verdePrincipal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  ),
);
  }
}
