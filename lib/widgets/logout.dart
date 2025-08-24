import 'package:flutter/material.dart';
import '../screens/user_session.dart';

class Logout extends StatelessWidget {
  const Logout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await UserSession.clearSession();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      },
      backgroundColor: Colors.teal,
      child: const Icon(Icons.logout, color: Colors.white),
    );
  }
}
