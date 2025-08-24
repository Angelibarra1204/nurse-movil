import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../screens/user_session.dart';

class MedicamentoService {
  static const _baseUrl = 'https://nursemovil.bsite.net/api/Medicamentos';

  static DateTime? _fechaUltimoRefresh;
  static DateTime? _inicioSesion;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final f1 = prefs.getString('fechaUltimoRefresh');
    final f2 = prefs.getString('inicioSesion');

    if (f1 != null) _fechaUltimoRefresh = DateTime.tryParse(f1)?.toUtc();
    if (f2 != null) _inicioSesion = DateTime.tryParse(f2)?.toUtc();
  }

  static Future<void> _guardarFechas() async {
    final prefs = await SharedPreferences.getInstance();
    if (_fechaUltimoRefresh != null) {
      await prefs.setString('fechaUltimoRefresh', _fechaUltimoRefresh!.toIso8601String());
    }
    if (_inicioSesion != null) {
      await prefs.setString('inicioSesion', _inicioSesion!.toIso8601String());
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMedicamentosFiltrados() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode != 200) return [];

    final List all = json.decode(response.body);
    final usuarioId = int.tryParse(UserSession.userId);
    final List<Map<String, dynamic>> userMeds = all
        .where((m) => m['Id_Usuario'] == usuarioId)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (_inicioSesion != null) {
      return userMeds.where((m) {
        final f = DateTime.parse(m['FechaHora']).toUtc();
        return f.isAfter(_inicioSesion!) || f.isAtSameMomentAs(_inicioSesion!);
      }).toList();
    }

    return userMeds;
  }

  static Future<void> addMedicamento(Map<String, dynamic> med) async {
    med["Id_Usuario"] = int.parse(UserSession.userId);
    med["FechaHora"] = DateTime.now().toIso8601String();
    await http.post(Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(med),
    );
  }

  static Future<void> updateMedicamento(String id, Map<String, dynamic> med) async {
    await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(med),
    );
  }

  static Future<void> deleteMedicamento(String id) async {
    await http.delete(Uri.parse('$_baseUrl/$id'));
  }

  static Future<void> handleRefresh(List<Map<String, dynamic>> medicamentosActuales) async {
    if (_inicioSesion == null) {
      _inicioSesion = DateTime.now().toUtc();
    }

    if (medicamentosActuales.isNotEmpty) {
      medicamentosActuales.sort((a, b) => DateTime.parse(b['FechaHora']).compareTo(DateTime.parse(a['FechaHora'])));
      _fechaUltimoRefresh = DateTime.parse(medicamentosActuales.first['FechaHora']).toUtc();
    } else {
      _fechaUltimoRefresh = null;
    }

    await _guardarFechas();
  }

  static Future<void> reiniciarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    _inicioSesion = null;
    await prefs.remove('inicioSesion');
  }
}
