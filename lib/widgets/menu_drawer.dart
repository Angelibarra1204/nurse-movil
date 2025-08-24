import 'package:flutter/material.dart';
import '../screens/Calendario.dart';
import '../screens/generaldata.dart';
import '../screens/login.dart';
import '../screens/SignosVitales.dart';
import '../screens/AdminMed.dart';
import '../screens/Evacuaciones.dart';
import '../screens/Notas.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text(
              'Menú Principal',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Turno del enfermero'),
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const DatosGeneralesPaciente()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('Signos Vitales'),
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const VitalSignsScreen()));
            },            
          ),
          ListTile(
            leading: const Icon(Icons.local_pharmacy),
            title: const Text('Medicamentos'),
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MedAdminScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('Evacuaciones y Alimentos'),
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const EvacuacionesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('Notas'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NotasScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Calendario'),
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
          ),
        ],
      ),
    );
  }
}
