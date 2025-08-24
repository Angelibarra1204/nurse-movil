// import 'package:flutter/material.dart';
// import '../widgets/custon_button.dart';
// import '../widgets/logout.dart';
// import 'login.dart';
// import 'calendar.dart';
// import 'generaldata.dart';
// import 'vitalsigns.dart';



// class Home extends StatelessWidget {
//   const Home({Key? key}) : super(key: key);

//    void _logout(BuildContext context) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const Login()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFB2F4DB), Color(0xFFE0F8F3)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.green.shade200,
//                   child: const Text(
//                     'NM',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 CustomButton(
//                   text: 'Datos generales del paciente',
//   onPressed: () {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const DatosGeneralesPaciente()),
//     );
//   },
//                   color: Colors.green.shade300,
//                 ),
//                 CustomButton(
//                   text: 'Signos Vitales',
//                   onPressed: () {},
//                   color: Colors.green.shade200,
//                 ),
//                 CustomButton(
//                   text: 'Medicamentos',
//                   onPressed: () {},
//                   color: Colors.green.shade400,
//                 ),
//                 CustomButton(
//                   text: 'Evacuaciones y Alimentos',
//                   onPressed: () {},
//                   color: Colors.green.shade300,
//                 ),
//                 CustomButton(
//                   text: 'Notas',
//                   onPressed: () {},
//                   color: Colors.green.shade200,
//                 ),
// CustomButton(
//   text: 'Calendario',
//   onPressed: () {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const CalendarScreen()),
//     );
//   },
//   color: Colors.green.shade400,
// ),
//               ],
//             ),
//           ),
//         ), 
//      ),
//       floatingActionButton: Logout(
//         onLogout: () => _logout(context),
//     ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }
// }


 



