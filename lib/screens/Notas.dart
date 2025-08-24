import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/menu_drawer.dart';
import 'user_session.dart';
import 'Evacuaciones.dart';
import 'generaldata.dart';


class NotasScreen extends StatefulWidget {
  const NotasScreen({Key? key}) : super(key: key);

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  final _colabCtrl = TextEditingController();
  final _indepCtrl = TextEditingController();
  final _respCtrl = TextEditingController();

  bool _loading = false;
  String? _mensaje;

  Future<void> _enviarNotas() async {
    setState(() {
      _loading = true;
      _mensaje = null;
    });

    final nota = {
      "Id": "",
      "IntervencionColaboracion": _colabCtrl.text.trim(),
      "ProblemasIndependientes": _indepCtrl.text.trim(),
      "RespuestaEvolucion": _respCtrl.text.trim(),
      "Id_Usuario": int.tryParse(UserSession.userId) ?? 0,
      "FechaHora": DateTime.now().toIso8601String(),

    };

    final url = Uri.parse("https://nursemovil.bsite.net/api/Notas");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(nota),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _mensaje = "¡Notas guardadas exitosamente!";
        });
        _colabCtrl.clear();
        _indepCtrl.clear();
        _respCtrl.clear();
      } else {
        setState(() {
          _mensaje = "Error al guardar. Intenta de nuevo.";
        });
      }
    } catch (e) {
      setState(() {
        _mensaje = "Ocurrió un error: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _colabCtrl.dispose();
    _indepCtrl.dispose();
    _respCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notas", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.teal[50],
      drawer: const MenuDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(18),
              width: 320,
              decoration: BoxDecoration(
                color: const Color(0xFFCCF3EE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "NOTAS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _NotaSeccion(
                    titulo: "INTERVENCIÓN DE COLABORACIÓN",
                    controller: _colabCtrl,
                  ),
                  const SizedBox(height: 25),
                  _NotaSeccion(
                    titulo: "PROBLEMAS INDEPENDIENTES",
                    controller: _indepCtrl,
                  ),
                  const SizedBox(height: 25),
                  _NotaSeccion(
                    titulo: "RESPUESTA Y EVOLUCIÓN",
                    controller: _respCtrl,
                  ),
                  const SizedBox(height: 24),
                  if (_mensaje != null)
                    Text(
                      _mensaje!,
                      style: TextStyle(
                        color: _mensaje!.contains("exitosamente")
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _enviarNotas,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: const Text("Guardar", style: TextStyle( color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                                    SizedBox(height: 20),

                   Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    ElevatedButton(
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EvacuacionesScreen()),
      ),
      child: const Text('Anterior'),
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
    ),
    ElevatedButton(
      onPressed: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DatosGeneralesPaciente()),
      ),
      child: const Text('Regresar al Inicio'),
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
      ),
    );
  }
}

class _NotaSeccion extends StatelessWidget {
  final String titulo;
  final TextEditingController controller;

  const _NotaSeccion({
    required this.titulo,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.8,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
