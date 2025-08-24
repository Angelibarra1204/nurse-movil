// medicamento_dialog.dart
import 'package:flutter/material.dart';
import '../services/medicamento_service.dart';
import '../screens/user_session.dart';

Future<bool?> showMedDialog(BuildContext context, {Map? med, bool isEdit = false}) async {
  final TextEditingController medicamentoCtrl = TextEditingController(text: med?['Medicamento'] ?? '');
  final TextEditingController cantidadCtrl = TextEditingController(text: med?['Cantidad']?.toString() ?? '');
  String unidad = med?['Unidad'] ?? 'ml';
  String via = med?['Via'] ?? 'Oral';

  return showDialog<bool>(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text(isEdit ? "Editar medicamento" : "Agregar medicamento"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicamentoCtrl,
                decoration: const InputDecoration(labelText: 'Medicamento'),
              ),
              TextField(
                controller: cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
              DropdownButtonFormField(
                value: unidad,
                items: ['ml', 'g']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => unidad = val as String,
                decoration: const InputDecoration(labelText: 'Unidad'),
              ),
              DropdownButtonFormField(
                value: via,
                items: ['Oral', 'IV', 'IM', 'Subcutánea']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => via = val as String,
                decoration: const InputDecoration(labelText: 'Vía'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final ahora = DateTime.now().toUtc();
              final String fechaHoraString = ahora.toIso8601String();

              Map<String, dynamic> nuevo = {
                "Medicamento": medicamentoCtrl.text.trim(),
                "Cantidad": int.tryParse(cantidadCtrl.text) ?? 0,
                "Unidad": unidad,
                "Via": via,
                "FechaHora": isEdit ? med!['FechaHora'] : fechaHoraString,
                "Id_Usuario": int.tryParse(UserSession.userId) ?? 0,
              };

              if (isEdit) {
                await MedicamentoService.updateMedicamento(med!['Id'].toString(), nuevo);
              } else {
                await MedicamentoService.addMedicamento(nuevo);
              }

              Navigator.pop(context, true);
            },
            child: Text(isEdit ? "Actualizar" : "Agregar"),
          ),
        ],
      );
    },
  );
}
