// main_screen.dart
import 'package:flutter/material.dart';
import '../services/medicamento_service.dart';
import '../widgets/medicamento_dialog.dart';
import '../widgets/menu_drawer.dart';
import 'Evacuaciones.dart';
import 'SignosVitales.dart';

class MedAdminScreen extends StatefulWidget {
  const MedAdminScreen({Key? key}) : super(key: key);

  @override
  State<MedAdminScreen> createState() => _MedAdminScreenState();
}

class _MedAdminScreenState extends State<MedAdminScreen> {
  List<Map<String, dynamic>> medicamentos = [];
  bool isLoading = true;
  final Set<String> ocultos = {};

  @override
  void initState() {
    super.initState();
    MedicamentoService.init().then((_) => fetchMedicamentos());
  }

  Future<void> fetchMedicamentos() async {
    setState(() => isLoading = true);
    final result = await MedicamentoService.fetchMedicamentosFiltrados();
    setState(() {
      medicamentos = result.where((med) {
        final id = med['Id']?.toString() ?? '';
        return !ocultos.contains(id);
      }).toList();
      isLoading = false;
    });
  }

  void onAgregar() async {
    final agregado = await showMedDialog(context);
    if (agregado == true) await fetchMedicamentos();
  }

  void onEditar(Map<String, dynamic> med) async {
    final actualizado = await showMedDialog(context, med: med, isEdit: true);
    if (actualizado == true) await fetchMedicamentos();
  }

  void onEliminar(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar medicamento?"),
        content: Text("¿Seguro que deseas eliminar '$nombre'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          )
        ],
      ),
    );
    if (confirm == true) {
      await MedicamentoService.deleteMedicamento(id);
      await fetchMedicamentos();
    }
  }

  void onRefresh() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Nuevo registro?"),
        content: const Text("Esto ocultará los medicamentos anteriores si se agrega uno nuevo después."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sí, continuar"),
          )
        ],
      ),
    );

    if (confirm == true) {
      for (var med in medicamentos) {
        final id = med['Id']?.toString();
        if (id != null) ocultos.add(id);
      }
      await fetchMedicamentos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCFF7F1),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("Administración de Medicamentos", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(onPressed: onAgregar, icon: const Icon(Icons.add_circle_outline, color: Colors.white)),
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 780,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const HeaderRow(),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: medicamentos.length,
                                itemBuilder: (context, index) {
                                  final med = medicamentos[index];
                                  return MedicamentoCard(
                                    medicamento: med,
                                    onEdit: () => onEditar(med),
                                    onDelete: () => onEliminar(med['Id'].toString(), med['Medicamento']),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VitalSignsScreen())),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: const Text("Anterior"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EvacuacionesScreen())),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: const Text("Siguiente"),
                      )
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class HeaderRow extends StatelessWidget {
  const HeaderRow({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          SizedBox(width: 16),
          SizedBox(width: 140, child: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 80, child: Text("Cantidad", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 50, child: Text("ml.", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 50, child: Text("g.", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 150, child: Text("Tipo de vía", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text("Hora", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}

class NavigationRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VitalSignsScreen())),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: const Text("Anterior"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EvacuacionesScreen())),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: const Text("Siguiente"),
        )
      ],
    );
  }
}

class MedicamentoCard extends StatelessWidget {
  final Map<String, dynamic> medicamento;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicamentoCard({super.key, required this.medicamento, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(width: 150, child: Text(medicamento['Medicamento'] ?? '')),
              SizedBox(width: 80, child: Text(medicamento['Cantidad'].toString(), textAlign: TextAlign.center)),
              SizedBox(
                width: 50,
                child: Radio<String>(value: 'ml', groupValue: medicamento['Unidad'], onChanged: null),
              ),
              SizedBox(
                width: 50,
                child: Radio<String>(value: 'g', groupValue: medicamento['Unidad'], onChanged: null),
              ),
              SizedBox(width: 150, child: Text(medicamento['Via'] ?? '', textAlign: TextAlign.center)),
              SizedBox(
                width: 80,
                child: Text(
                  medicamento['FechaHora'] != null
                      ? DateTime.parse(medicamento['FechaHora']).toLocal().toString().substring(11, 16)
                      : '--',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.teal), onPressed: onEdit),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
