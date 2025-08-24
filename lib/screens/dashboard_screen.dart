import 'package:flutter/material.dart';
import '../widgets/nav_tabs.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/users_tab.dart';
import '../widgets/documents_tab.dart';
import '../widgets/calendarwidget.dart';
import '../widgets/logout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTab = 0;

  final List<String> _tabTitles = [
    'Dashboard',
    'Enfermeros',
    'Bitácoras',
    'Calendario',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA8E6CF),
      floatingActionButton: const Logout(), // Botón de cerrar sesión
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA8E6CF), Color(0xFF33C49F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1400),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '🏥 Panel de Administrador - Nurse Movil',
                          style: TextStyle(
                            color: Color(0xFF22543D),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Gestiona usuarios, bitácoras y calendario',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF22543D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs horizontales
                  NavTabs(
                    currentIndex: _currentTab,
                    titles: _tabTitles,
                    onTabSelected: (index) {
                      setState(() => _currentTab = index);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Contenido de cada pestaña
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentTab == 0
                          ? const DashboardTab(key: ValueKey('dash'))
                          : _currentTab == 1
                              ? const UsersTab(key: ValueKey('users'))
                             : _currentTab == 2
                              ? SingleChildScrollView(
                                  key: const ValueKey('bitacoras'),
                                  padding: const EdgeInsets.all(8),
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '📄 Bitácoras de Turno',
                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Filtra por nombre o rango de fechas...',
                                            style: TextStyle(fontSize: 16, color: Colors.black54),
                                          ),
                                          const SizedBox(height: 20),
                                          BitacoraSearchSection(),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                  : SingleChildScrollView(
                                      key: const ValueKey('calendario'),
                                      padding: const EdgeInsets.all(8),
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: const CalendarWidget(),
                                        ),
                                      ),
                                    ),
                    ),
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
