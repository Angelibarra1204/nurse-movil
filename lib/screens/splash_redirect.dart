import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'generaldata.dart';
import 'user_session.dart';
import 'login.dart';

class SplashRedirect extends StatelessWidget {
  const SplashRedirect({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Aquí deberías guardar también el tipo de usuario en la sesión (como Paciente o Enfermero)
    // Supongamos que lo guardas como: UserSession.userType = 'Paciente' o 'Enfermero'

    final tipo = UserSession.userType; // Debes agregar esto en tu clase UserSession

    if (tipo == 'Paciente') {
      return const AdminDashboardScreen();
    } else if (tipo == 'Enfermero') {
      return const DatosGeneralesPaciente();
    } else {
      // Fallback
      return const Login();
    }
  }
}
