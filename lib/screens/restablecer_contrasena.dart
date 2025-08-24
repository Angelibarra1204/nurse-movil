import 'package:flutter/material.dart';
import '../services/api.dart';

class RestablecerContrasenaScreen extends StatefulWidget {
  const RestablecerContrasenaScreen({super.key});

  @override
  State<RestablecerContrasenaScreen> createState() => _RestablecerContrasenaScreenState();
}

class _RestablecerContrasenaScreenState extends State<RestablecerContrasenaScreen> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _respuestaSegController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _restablecerContrasena() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = {
      "Correo": _correoController.text.trim(),
      "Respuesta_Seguridad": _respuestaSegController.text.trim(),
      "Contrasena": _passController.text.trim(),
      "Confirmar_contrasena": _confirmPassController.text.trim(),
    };

    final response = await Api.restablecerContrasena(body);

    setState(() => _isLoading = false);

    if (response['Success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña restablecida correctamente.')),
      );
      Navigator.pop(context);
    } else {
      final msg = response['Message'] ?? 'No se pudo restablecer la contraseña.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Para restablecer tu contraseña, responde la siguiente pregunta de seguridad.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa tu correo';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Cuál fue el nombre de tu primer mascota?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _respuestaSegController,
                decoration: const InputDecoration(
                  labelText: 'Respuesta de seguridad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.question_answer),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa la respuesta de seguridad';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != _passController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _restablecerContrasena,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Restablecer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
