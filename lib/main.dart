import 'package:flutter/material.dart';
import 'screens/Calendario.dart';
import 'screens/Notas.dart';
import 'screens/login.dart';
import 'screens/generaldata.dart';
import 'screens/dashboard_screen.dart';
import 'screens/user_session.dart';
import 'screens/splash_redirect.dart';
import 'screens/Terminos_Condiciones.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserSession.loadUserId(); // Cargar userId guardado
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nurse Movil',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const TerminosCondiciones(),
      routes: {
        '/Calendario': (context) => const CalendarScreen(),
        '/generaldata': (context) => const DatosGeneralesPaciente(),
        '/dashboard': (context) => const AdminDashboardScreen(),
        '/Notas': (context) => const NotasScreen(),
        // Ruta login
        '/login': (context) => const Login(),
      },
    );
  }
}
