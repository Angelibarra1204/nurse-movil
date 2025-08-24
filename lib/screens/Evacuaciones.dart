import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/menu_drawer.dart';
import 'user_session.dart'; 
import 'AdminMed.dart';
import 'Notas.dart';

class EvacuacionesScreen extends StatefulWidget {
  const EvacuacionesScreen({Key? key}) : super(key: key);

  @override
  State<EvacuacionesScreen> createState() => _EvacuacionesScreenState();
}

class _EvacuacionesScreenState extends State<EvacuacionesScreen> {
  int? miccion;
  int? evacuacionIntestinal;
  int? miccionCustom;
  int? evacuacionCustom;
  final TextEditingController alimentoInputController = TextEditingController();
  final TextEditingController miccionCustomController = TextEditingController();
  final TextEditingController evacuacionCustomController = TextEditingController();

  List<int> opciones = [1, 2, 3, 4];
  List<String> alimentosList = [];

  bool showMiccionCustomField = false;
  bool showEvacuacionCustomField = false;

  int get totalEgresos => (miccion ?? 0) + (miccionCustom ?? 0) + (evacuacionIntestinal ?? 0) + (evacuacionCustom ?? 0);
  int get totalIngresos => alimentosList.length;

  Future<void> guardarEvacuacion() async {
  if ((miccion == null && miccionCustom == null) || (evacuacionIntestinal == null && evacuacionCustom == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa ambos campos de micción y evacuación')),
      );
      return;
    }

    if (alimentosList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agrega al menos un alimento')),
      );
      return;
    }

    final miccionFinal = miccion ?? miccionCustom ?? 0;
    final evacuacionFinal = evacuacionIntestinal ?? evacuacionCustom ?? 0;

    final Map<String, dynamic> data = {
      "Miccion": "$miccionFinal ${miccionFinal == 1 ? "vez" : "veces"}",
      "EvacuacionIntestinal": "$evacuacionFinal ${evacuacionFinal == 1 ? "vez" : "veces"}",
      "EgresosAlimento": totalEgresos,
      "Alimento": alimentosList.join(', '),
      "IngresosAlimento": totalIngresos,
      "Id_Usuario": int.tryParse(UserSession.userId) ?? 0,
      "FechaHora": DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('https://nursemovil.bsite.net/api/Evacuaciones'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datos guardados correctamente')),
        );
        setState(() {
          miccion = null;
          evacuacionIntestinal = null;
          alimentosList.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red o servidor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text("Formulario de Paciente", style: TextStyle(color: Colors.white)),
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
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "EVACUACIONES",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 22),
                  Text(
                    "¿CUÁNTAS VECES HA MICCIONADO EL PACIENTE?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [...opciones, "+4 veces"].map((option) {
                      return ChoiceChip(
                        label: option is int
                            ? Text('$option ${option == 1 ? "vez" : "veces"}')
                            : const Text('+4 veces'),
                        selected: miccion == option || miccionCustom != null,
                        onSelected: (_) {
                          setState(() {
                            if (option is int) {
                              miccion = option;
                              miccionCustom = null;
                            } else {
                              miccion = null;
                              miccionCustom = 0;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (miccionCustom != null)
                    Column(
                      children: [
                        SizedBox(height: 10),
                        TextField(
                          controller: miccionCustomController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Ingresa la cantidad',
                          ),
                          onChanged: (value) {
                            setState(() {
                              miccionCustom = int.tryParse(value);
                            });
                          },
                        ),
                      ],
                    ),
                  SizedBox(height: 22),
                  Text(
                    "¿CUÁNTAS EVACUACIONES INTESTINALES HA TENIDO EL PACIENTE?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [...opciones, "+4 veces"].map((option) {
                      return ChoiceChip(
                        label: option is int
                            ? Text('$option ${option == 1 ? "vez" : "veces"}')
                            : const Text('+4 veces'),
                        selected: evacuacionIntestinal == option || evacuacionCustom != null,
                        onSelected: (_) {
                          setState(() {
                            if (option is int) {
                              evacuacionIntestinal = option;
                              evacuacionCustom = null;
                            } else {
                              evacuacionIntestinal = null;
                              evacuacionCustom = 0;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (evacuacionCustom != null)
                    Column(
                      children: [
                        SizedBox(height: 10),
                        TextField(
                          controller: evacuacionCustomController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Ingresa la cantidad',
                          ),
                          onChanged: (value) {
                            setState(() {
                              evacuacionCustom = int.tryParse(value);
                            });
                          },
                        ),
                      ],
                    ),
                  SizedBox(height: 18),
                  Text("TOTAL DE EGRESOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Text(
                      '$totalEgresos',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                    ),
                  ),
                  SizedBox(height: 22),
                  Text(
                    "ALIMENTOS",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: alimentoInputController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                            hintText: 'Agregar alimento...',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          String alimento = alimentoInputController.text.trim();
                          if (alimento.isNotEmpty) {
                            setState(() {
                              alimentosList.add(alimento);
                              alimentoInputController.clear();
                            });
                          }
                        },
                        child: Text('Agregar'),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  ...alimentosList.map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.shade100)
                      ),
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(a),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setState(() {
                                alimentosList.remove(a);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
                  SizedBox(height: 18),
                  Text("TOTAL DE INGRESOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Text(
                      '$totalIngresos',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: guardarEvacuacion,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MedAdminScreen()),
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
                                MaterialPageRoute(builder: (context) => const NotasScreen()),
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
      ),
    );
  }
}
