import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/menu_drawer.dart';
import 'package:flutter/services.dart';
import 'user_session.dart';
import 'generaldata.dart';
import 'AdminMed.dart';

const List<String> keysApi = [
  "Temperatura",
  "PresionArterial",
  "FrecuenciaCardiaca",
  "FrecuenciaRespiratoria",
  "SaturacionO2",
  "Dextrostix"
];

const List<String> labels = [
  "Temperatura",
  "Presión arterial",
  "Frecuencia cardíaca",
  "Frecuencia respiratoria",
  "Saturación O2",
  "Dextrostix"
];

class VitalSignsScreen extends StatefulWidget {
  const VitalSignsScreen({Key? key}) : super(key: key);

  @override
  State<VitalSignsScreen> createState() => _VitalSignsScreenState();
}

class _VitalSignsScreenState extends State<VitalSignsScreen> {
  List<TextEditingController> valueControllers = [];
  List<TextEditingController> timeControllers = [];
  bool isLoading = true;
  Map<String, dynamic>? ultimosSignos;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < keysApi.length; i++) {
      valueControllers.add(TextEditingController());
      timeControllers.add(TextEditingController());
    }
    fetchSignos();
  }
  
  bool tieneDatosCargados = false;

  Future<void> fetchSignos() async {
    
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse('https://nursemovil.bsite.net/api/Signos'));
    if (response.statusCode == 200) {
      final List<dynamic> lista = json.decode(response.body);

      final signosUsuario = lista.lastWhere(
        (e) => e['Id_Usuario'].toString() == UserSession.userId,
        orElse: () => null,
      );
      tieneDatosCargados = false;

  if (signosUsuario != null) {
    for (int i = 0; i < keysApi.length; i++) {
      var listaCampo = signosUsuario[keysApi[i]] as List?;
      if (listaCampo != null && listaCampo.isNotEmpty) {
        valueControllers[i].text = listaCampo[0]['Numero'].toString();
        timeControllers[i].text = listaCampo[0]['Hora'].toString();
        tieneDatosCargados = true;
      } else {
        valueControllers[i].clear();
        timeControllers[i].clear();
      }
    }
  } else {
    for (int i = 0; i < keysApi.length; i++) {
      valueControllers[i].clear();
      timeControllers[i].clear();
    }
    tieneDatosCargados = false;
  }
    }
    
    setState(() => isLoading = false);

    setState(() {}); // Para que se actualice el botón

  }

  String? _validateSign(String label, String value, String hora) {
    if (value.isEmpty) return 'El campo $label no puede estar vacío';
    final horaRegex = RegExp(r'^\d{2}:\d{2}$');
    if (!horaRegex.hasMatch(hora)) return 'La hora para $label es inválida';

    double parsedValue = double.tryParse(value) ?? -1;

    switch (label) {
      case 'Temperatura':
        if (parsedValue < 30 || parsedValue > 43) {
          return 'La temperatura debe estar entre 30°C y 43°C';
        }
        break;

      case 'Presión arterial':
        var parts = value.split('/');
        if (parts.length == 2) {
          int systolic = int.tryParse(parts[0]) ?? -1;
          int diastolic = int.tryParse(parts[1]) ?? -1;

          if (systolic < 60 || systolic > 180) {
            return 'La presión sistólica debe estar entre 60 y 180 mmHg';
          }
          if (diastolic < 40 || diastolic > 120) {
            return 'La presión diastólica debe estar entre 40 y 120 mmHg';
          }
        } else {
          return 'Formato incorrecto para la presión arterial. Ejemplo: 120/80';
        }
        break;

      case 'Frecuencia cardíaca':
        if (parsedValue < 40 || parsedValue > 180) {
          return 'La frecuencia cardíaca debe estar entre 40 y 180 latidos por minuto';
        }
        break;

      case 'Frecuencia respiratoria':
        if (parsedValue < 10 || parsedValue > 40) {
          return 'La frecuencia respiratoria debe estar entre 10 y 40 respiraciones por minuto';
        }
        break;

      case 'Saturación O2':
        if (parsedValue < 70 || parsedValue > 100) {
          return 'La saturación de oxígeno debe estar entre 70% y 100%';
        }
        break;

      case 'Dextrostix':
        if (parsedValue < 60 || parsedValue > 600) {
          return 'El nivel de glucosa debe estar entre 60 y 600 mg/dL';
        }
        break;
    }
    return null;
  }

  Future<void> guardarSignos() async {
    Map<String, dynamic> body = {};
    bool hasError = false;

    for (int i = 0; i < keysApi.length; i++) {
      String value = valueControllers[i].text.trim();
      String hora = timeControllers[i].text.trim();

      String? validationMessage = _validateSign(labels[i], value, hora);
      if (validationMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationMessage)));
        hasError = true;
        break;
      }

      double? number = double.tryParse(valueControllers[i].text.replaceAll(',', '.'));
      if (number == null) {
        number = 0;
      }

      if (keysApi[i] == "PresionArterial") {
        List<String> presionValues = valueControllers[i].text.split('/');
        if (presionValues.length == 2) {
          int sistolica = int.tryParse(presionValues[0]) ?? 0;
          int diastolica = int.tryParse(presionValues[1]) ?? 0;
          
          if (sistolica < 60 || sistolica > 180 || diastolica < 40 || diastolica > 120) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('La presión arterial debe estar entre 60/40 y 180/120')),
            );
            return;
          }

          body[keysApi[i]] = [
            {
              "Numero": "$sistolica/$diastolica",
              "Hora": timeControllers[i].text,
            }
          ];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El formato de la presión arterial es incorrecto')),
          );
          return;
        }
      } else {
        body[keysApi[i]] = [
          {
            "Numero": number,
            "Hora": timeControllers[i].text,
          }
        ];
      }
    }

    if (hasError) return;

  body["Id_Usuario"] = int.parse(UserSession.userId);
  body["FechaHora"] = DateTime.now().toUtc().toIso8601String();


    final response = await http.post(
      Uri.parse('https://nursemovil.bsite.net/api/Signos'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signos vitales guardados correctamente')),
      );
      ultimosSignos = Map<String, dynamic>.from(body);

      setState(() {});
      await fetchSignos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar signos vitales')),
      );
    }
  }

  @override
  void dispose() {
    for (var c in valueControllers) {
      c.dispose();
    }
    for (var c in timeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text("Signos Vitales", style: TextStyle(color: Colors.white),
        ),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      ...List.generate(keysApi.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(labels[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 35,
                                      child: TextField(
                                        controller: valueControllers[i],
                                        keyboardType: TextInputType.text,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^[0-9/.,]+$')),
                                        ],
                                        decoration: InputDecoration(
                                          fillColor: Colors.white,
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        onChanged: (v) {
                                          if (v.isNotEmpty && timeControllers[i].text.isEmpty) {
                                            final now = TimeOfDay.now();
                                            timeControllers[i].text =
                                                "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('HORA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 35,
                                      child: TextField(
                                        controller: timeControllers[i],
                                        readOnly: false,
                                        decoration: InputDecoration(
                                          fillColor: Colors.white,
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.access_time),
                                            onPressed: () async {
                                              final now = TimeOfDay.now();
                                              final picked = await showTimePicker(
                                                context: context,
                                                initialTime: now,
                                              );
                                              if (picked != null) {
                                                setState(() {
                                                  timeControllers[i].text =
                                                      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                        keyboardType: TextInputType.datetime,
                                        onTap: () async {
                                          final now = TimeOfDay.now();
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: now,
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              timeControllers[i].text =
                                                  "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 22),
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            tieneDatosCargados ? Icons.refresh : Icons.save,
                            color: Colors.white,
                          ),
                          label: Text(
                            tieneDatosCargados ? "Hacer nuevo registro" : "Guardar todos",
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (tieneDatosCargados) {
                              for (var controller in valueControllers) {
                                controller.clear();
                              }
                              for (var controller in timeControllers) {
                                controller.clear();
                              }
                              setState(() {
                                tieneDatosCargados = false;
                              });
                            } else {
                              guardarSignos();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DatosGeneralesPaciente()),
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
                                    MaterialPageRoute(builder: (context) => const MedAdminScreen()),
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
