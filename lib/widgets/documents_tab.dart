import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

void generarYMostrarPDF(BuildContext context, Map<String, dynamic> bitacora) async {
  final pdf = pw.Document();

  String formatFecha(String fecha) => fecha.split('T')[0];

  pw.Widget buildNotas(List<List<dynamic>> registros) {
  if (registros.isEmpty) return pw.Text('Notas: Sin registros');

  final nota = registros[0];
  final widgets = <pw.Widget>[];

  for (var campo in ['IntervencionColaboracion', 'ProblemasIndependientes', 'RespuestaEvolucion']) {
    final item = nota.firstWhere((e) => e['Name'] == campo, orElse: () => null);
    final valor = item != null ? item['Value'].toString() : '';

    String titulo;
    switch (campo) {
      case 'IntervencionColaboracion':
        titulo = 'Intervención colaboración';
        break;
      case 'ProblemasIndependientes':
        titulo = 'Problemas independientes';
        break;
      case 'RespuestaEvolucion':
        titulo = 'Respuesta evolución';
        break;
      default:
        titulo = campo;
    }

    widgets.add(
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {0: const pw.FlexColumnWidth()},
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  titulo,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.left,
                ),
              ),
            ],
          ),
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  valor,
                  textAlign: pw.TextAlign.left,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    widgets.add(pw.SizedBox(height: 10));
  }

  return pw.Column(children: widgets);
}

pw.Widget buildSignosVitales(List<List<dynamic>> registros) {
  if (registros.isEmpty) return pw.Text('Signos Vitales: Sin registros');

  final signo = registros[0];
  final List<List<dynamic>> filas = [];

  final nombresPersonalizados = {
    'Temperatura': 'Temperatura',
    'PresionArterial': 'Presión arterial',
    'FrecuenciaCardiaca': 'Frecuencia cardíaca',
    'FrecuenciaRespiratoria': 'Frecuencia respiratoria',
    'SaturacionO2': 'Saturación O2',
    'Dextrostix': 'Dextrostix'
  };
  for (var key in nombresPersonalizados.keys) {
    final item = signo.firstWhere((e) => e['Name'] == key, orElse: () => null);
    if (item != null && item['Value'] is List && item['Value'].isNotEmpty) {
      final registrosInternos = item['Value'][0];
      dynamic numeroValue;
      String horaValue = '';

      for (var subRegistro in registrosInternos) {
        if (subRegistro['Name'] == 'Numero') numeroValue = subRegistro['Value'];
        else if (subRegistro['Name'] == 'Hora') horaValue = subRegistro['Value']?.toString() ?? '';
      }

      filas.add([nombresPersonalizados[key], numeroValue, horaValue]);
    } else {
      filas.add([nombresPersonalizados[key], '', '']);
    }
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Signos Vitales:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: ['Signo', 'Registro', 'Hora'],
        data: filas.map((row) => row.map((cell) => cell?.toString() ?? '').toList()).toList(),
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignment: pw.Alignment.centerLeft,
      ),
    ],
  );
}

pw.Widget buildEvacuaciones(List<List<dynamic>> registros) {
  if (registros.isEmpty) return pw.Text('Evacuaciones: Sin registros');

  final evac = registros[0];

  String obtenerValor(String campo) {
    final item = evac.firstWhere((e) => e['Name'] == campo, orElse: () => null);
    return item != null ? item['Value'].toString() : '';
  }

  final filas = <List<String>>[
    ['Micción', obtenerValor('Miccion')],
    ['Evacuación intestinal', obtenerValor('EvacuacionIntestinal')],
    ['Total de egresos', obtenerValor('EgresosAlimento')],
  ];

  final alimentos = obtenerValor('Alimento').split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
  final totalComidas = obtenerValor('IngresosAlimento');

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Evacuaciones:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: ['Tipo de egreso', 'Cantidad'],
        data: filas,
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignment: pw.Alignment.centerLeft,
      ),
      pw.SizedBox(height: 10),
      if (alimentos.isNotEmpty) ...[
        pw.Text('Alimentos:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 4),
        ...alimentos.map((a) => pw.Bullet(text: a)),
        pw.SizedBox(height: 10),
      ],
      if (totalComidas.isNotEmpty)
        pw.Text('Total de comidas: $totalComidas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
    ],
  );
}


pw.Widget buildMedicamentos(List<List<dynamic>> registros) {
  if (registros.isEmpty) return pw.Text('Medicamentos: Sin registros');

  final med = registros[0];
  String obtenerValor(String campo) {
    final item = med.firstWhere((e) => e['Name'] == campo, orElse: () => null);
    return item != null ? item['Value'].toString() : '';
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Administración de medicamentos:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: ['Medicamento', 'Cantidad', 'Unidad', 'Vía'],
        data: [
          [
            obtenerValor('Medicamento'),
            obtenerValor('Cantidad'),
            obtenerValor('Unidad'),
            obtenerValor('Via'),
          ]
        ],
        border: pw.TableBorder.all(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        cellAlignment: pw.Alignment.centerLeft,
      ),
    ],
  );
}

  final datos = bitacora['Datos'] as List<dynamic>;
  final descripcion = bitacora['Descripcion'] ?? '';
  final fecha = bitacora['FechaHora'] ?? '';
  final nombreEnfermero = bitacora['NombreEnfermero'] ?? 'Desconocido';
  final nombrePaciente = bitacora['NombrePaciente'] ?? 'Paciente desconocido';

  final notas = datos.firstWhere((e) => e['Name'] == 'Notas', orElse: () => {'Value': []})['Value'] as List<dynamic>;
  final signos = datos.firstWhere((e) => e['Name'] == 'SignosVitales', orElse: () => {'Value': []})['Value'] as List<dynamic>;
  final evacuaciones = datos.firstWhere((e) => e['Name'] == 'Evacuaciones', orElse: () => {'Value': []})['Value'] as List<dynamic>;
  final medicamentos = datos.firstWhere((e) => e['Name'] == 'Medicamentos', orElse: () => {'Value': []})['Value'] as List<dynamic>;

pdf.addPage(
  pw.MultiPage(
    build: (pw.Context context) => [
      pw.Text('Bitácora de Turno', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Text('Paciente: $nombrePaciente'),
      pw.SizedBox(height: 12),
      pw.Text('Fecha: ${formatFecha(fecha)}'),
      pw.SizedBox(height: 10),
      pw.Text('Registrado por: $nombreEnfermero'),
      pw.SizedBox(height: 10),
      pw.Divider(),
      pw.SizedBox(height: 10),
      buildSignosVitales(signos is List && signos.isNotEmpty && signos.first is List ? signos.cast<List<dynamic>>() : []),
      pw.SizedBox(height: 20),
      buildEvacuaciones(evacuaciones is List && evacuaciones.isNotEmpty && evacuaciones.first is List ? evacuaciones.cast<List<dynamic>>() : []),
      pw.SizedBox(height: 20),
      buildMedicamentos(medicamentos is List && medicamentos.isNotEmpty && medicamentos.first is List ? medicamentos.cast<List<dynamic>>() : []),
       pw.SizedBox(height: 20),
      buildNotas(notas is List && notas.isNotEmpty && notas.first is List ? notas.cast<List<dynamic>>() : []),
      pw.SizedBox(height: 20),
    ],
  ),
);

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

class DocumentsTab extends StatelessWidget {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String nombreEnfermero;

  const DocumentsTab({
    Key? key,
    required this.fechaInicio,
    required this.fechaFin,
    required this.nombreEnfermero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('documents'),
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
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '📄 Bitácoras de Turno',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF22543D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BitacoraTabla(
              fechaInicio: fechaInicio,
              fechaFin: fechaFin,
              nombreEnfermero: nombreEnfermero,
            ),
          ),
        ],
      ),
    );
  }
}

class BitacoraTabla extends StatefulWidget {
  const BitacoraTabla({
    Key? key,
    required this.fechaInicio,
    required this.fechaFin,
    required this.nombreEnfermero,
    this.nombrePaciente = '',
  }) : super(key: key);

  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String nombreEnfermero;
  final String nombrePaciente;

  @override
  State<BitacoraTabla> createState() => _BitacoraTablaState();
}

class _BitacoraTablaState extends State<BitacoraTabla> {
  Map<int, String> usuarioMapa = {};
  List<dynamic> bitacoras = [];
  bool cargando = true;

  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late String _nombreEnfermero;
  late String _nombrePaciente;

  @override
  void initState() {
    super.initState();
    _fechaInicio = widget.fechaInicio;
    _fechaFin = widget.fechaFin;
    _nombreEnfermero = widget.nombreEnfermero;
    _nombrePaciente = widget.nombrePaciente;
    cargarUsuariosYBitacoras();
  }

  void actualizarParametros({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String nombreEnfermero,
    String nombrePaciente = '',
  }) {
    setState(() {
      _fechaInicio = fechaInicio;
      _fechaFin = fechaFin;
      _nombreEnfermero = nombreEnfermero;
      _nombrePaciente = nombrePaciente;
    });
    cargarUsuariosYBitacoras();
  }

  Future<void> cargarUsuariosYBitacoras() async {
    setState(() => cargando = true);

    try {
      final usuariosResponse = await http.get(Uri.parse('https://nursemovil.bsite.net/api/Usuarios'));
      if (usuariosResponse.statusCode == 200) {
        final List<dynamic> usuariosData = jsonDecode(usuariosResponse.body);
        usuarioMapa = {
          for (var u in usuariosData) u['Id_Usuario']: '${u['Nombre']} ${u['Apellidos']}'
        };
      } else {
        throw Exception('Error al obtener usuarios');
      }

      final uriBitacoras = Uri.parse('https://nursemovil.bsite.net/api/BitacoraTurno/Todas');
      final bitacorasResponse = await http.get(uriBitacoras);

      if (bitacorasResponse.statusCode == 200) {
        List<dynamic> todasBitacoras = jsonDecode(bitacorasResponse.body);
        final filtroEnfermero = _nombreEnfermero.toLowerCase().trim();
        final filtroPaciente = _nombrePaciente.toLowerCase().trim();

        todasBitacoras = todasBitacoras.where((bitacora) {
          // Filtrar por nombre de enfermero
          final idUsuario = bitacora['Id_Usuario'];
          final nombreEnfermero = usuarioMapa[idUsuario]?.toLowerCase() ?? '';
          if (filtroEnfermero.isNotEmpty && !nombreEnfermero.contains(filtroEnfermero)) {
            return false;
          }

          // Filtrar por nombre de paciente
          final nombrePaciente = (bitacora['NombrePaciente'] ?? '').toString().toLowerCase();
          if (filtroPaciente.isNotEmpty && !nombrePaciente.contains(filtroPaciente)) {
            return false;
          }

          // Filtrar por fecha
          final fechaStr = bitacora['FechaHora'];
          final fecha = DateTime.tryParse(fechaStr)?.toLocal();
          if (fecha == null) return false;

          final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
          final inicioSolo = DateTime(_fechaInicio.year, _fechaInicio.month, _fechaInicio.day);
          final finSolo = DateTime(_fechaFin.year, _fechaFin.month, _fechaFin.day);

          return (fechaSolo.isAtSameMomentAs(inicioSolo) || fechaSolo.isAfter(inicioSolo)) &&
                (fechaSolo.isAtSameMomentAs(finSolo) || fechaSolo.isBefore(finSolo));
        }).toList();

        bitacoras = todasBitacoras;
      } else {
        throw Exception('Error al obtener bitácoras');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (bitacoras.isEmpty) return const Center(child: Text('No se encontraron bitácoras.'));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Enfermero')),
          DataColumn(label: Text('Paciente')),
        ],
        rows: bitacoras.map((bitacora) {
          final fecha = bitacora['FechaHora'] != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(
                DateTime.parse(bitacora['FechaHora']).toLocal(),
              )
            : '-';
          final idUsuario = bitacora['Id_Usuario'];
          final nombreEnfermero = usuarioMapa[idUsuario] ?? 'Desconocido';
          final nombrePaciente = bitacora['NombrePaciente'] ?? 'Paciente desconocido';

          void abrirPDF() {
            final bitacoraConNombre = <String, dynamic>{
              ...Map<String, dynamic>.from(bitacora),
              'NombreEnfermero': nombreEnfermero,
            };
            generarYMostrarPDF(context, bitacoraConNombre);
          }

          return DataRow(cells: [
            DataCell(
              InkWell(
                onTap: abrirPDF,
                child: Text(
                  fecha,
                ),
              ),
            ),
            DataCell(
              InkWell(
                onTap: abrirPDF,
                child: Text(
                  nombreEnfermero,
                ),
              ),
            ),
            DataCell(
              InkWell(
                onTap: abrirPDF,
                child: Text(nombrePaciente),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}

class BitacoraSearchSection extends StatefulWidget {
  const BitacoraSearchSection({Key? key}) : super(key: key);

  @override
  State<BitacoraSearchSection> createState() => _BitacoraSearchSectionState();
}

class _BitacoraSearchSectionState extends State<BitacoraSearchSection> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _nombrePacienteController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  final GlobalKey<_BitacoraTablaState> _tablaKey = GlobalKey<_BitacoraTablaState>();

  Future<void> _seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fechaInicio = picked);
  }

  Future<void> _seleccionarFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fechaFin = picked);
  }

  void _buscarBitacoras() {
    _tablaKey.currentState?.actualizarParametros(
      fechaInicio: _fechaInicio ?? DateTime.now().subtract(const Duration(days: 7)),
      fechaFin: _fechaFin ?? DateTime.now(),
      nombreEnfermero: _nombreController.text.trim(),
      nombrePaciente: _nombrePacienteController.text.trim(), // Nuevo parámetro
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre de enfermero',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nombrePacienteController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre de paciente',
                    prefixIcon: Icon(Icons.person_search),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _seleccionarFechaInicio,
                        icon: const Icon(Icons.date_range),
                        label: Text(_fechaInicio == null
                            ? 'Fecha Inicio'
                            : _fechaInicio!.toLocal().toString().split(' ')[0]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _seleccionarFechaFin,
                        icon: const Icon(Icons.date_range),
                        label: Text(_fechaFin == null
                            ? 'Fecha Fin'
                            : _fechaFin!.toLocal().toString().split(' ')[0]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _buscarBitacoras,
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 400,
          child: BitacoraTabla(
            key: _tablaKey,
            fechaInicio: DateTime.now().subtract(const Duration(days: 7)),
            fechaFin: DateTime.now(),
            nombreEnfermero: '',
          ),
        ),
      ],
    );
  }
}