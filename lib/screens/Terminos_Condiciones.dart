import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class TerminosCondiciones extends StatefulWidget {
  const TerminosCondiciones({Key? key}) : super(key: key);

  @override
  State<TerminosCondiciones> createState() => _TerminosCondicionesState();
}

class _TerminosCondicionesState extends State<TerminosCondiciones> {
  bool aceptoTerminos = false;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _verificarAceptacion();
  }

  Future<void> _verificarAceptacion() async {
    final prefs = await SharedPreferences.getInstance();
    final aceptado = prefs.getBool('terminos_aceptados') ?? false;

    if (aceptado) {
      _irALogin();
    } else {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> _guardarAceptacion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terminos_aceptados', true);
  }

  void _continuar() async {
    await _guardarAceptacion();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Gracias por aceptar los Términos y Condiciones!')),
    );

    _irALogin();
  }

  void _irALogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login()));
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Nurse Movil',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: const Text(
                  '''Por favor, lea detenidamente los siguientes Términos y Condiciones antes de utilizar esta aplicación móvil.

                    Esta aplicación está diseñada para ser utilizada únicamente por enfermeros independientes como una herramienta de registro clínico. Al aceptar estos términos, usted reconoce y acepta que es responsable del uso adecuado de la información ingresada en la aplicación, así como de mantener la confidencialidad de los datos personales de sus pacientes.

                    La aplicación no se hace responsable por el uso indebido de los datos, ni por fallos derivados del mal uso del sistema. Toda información registrada debe ser verídica y estar alineada con los principios éticos y legales del ejercicio profesional de enfermería.

                    Al utilizar esta aplicación, usted acepta que los datos almacenados podrán ser utilizados para mejorar el funcionamiento del sistema, respetando en todo momento la privacidad y seguridad de la información.''',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),

            const SizedBox(height: 20),

            CheckboxListTile(
              title: const Text('He leído y acepto los Términos y Condiciones'),
              value: aceptoTerminos,
              onChanged: (bool? value) {
                setState(() {
                  aceptoTerminos = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: aceptoTerminos ? _continuar : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
