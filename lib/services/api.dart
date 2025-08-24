import 'dart:convert';
import 'package:http/http.dart' as http;

class Api {
  static const String baseUrl = 'https://nursemovil.bsite.net/api';

  /// Autenticación de usuario manual (por lista)
  static Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Usuarios/Login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Correo': email,
          'Contrasena': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['Success'] == true) {
          return data;
        } else {
          return {
            'Success': false,
            'Message': data['Message'] ?? 'Error desconocido',
          };
        }
      } else {
        return {
          'Success': false,
          'Message': 'Error del servidor. Intente más tarde.',
        };
      }
    } catch (e) {
      return {
        'Success': false,
        'Message': 'Error de conexión. Verifique su red.',
      };
    }
  }

  /// Obtener cantidad total de usuarios
  static Future<int> getUsuariosCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Usuarios'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.length;
      }
    } catch (e) {
      print('Error usuarios: $e');
    }
    return 0;
  }

  static Future<int> getNotasCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Notas'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.length;
      }
    } catch (e) {
      print('Error notas: $e');
    }
    return 0;
  }

  static Future<int> getSignosCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Signos'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.length;
      }
    } catch (e) {
      print('Error signos: $e');
    }
    return 0;
  }

  static Future<int> getTurnosCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Turnos'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.length;
      }
    } catch (e) {
      print('Error turnos: $e');
    }
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getEnfermeros() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Usuarios'));
      if (response.statusCode == 200) {
        final List<dynamic> users = json.decode(response.body);
        return users
            .where((u) => u['Tipo_usuario'] == 'Enfermero')
            .cast<Map<String, dynamic>>()
            .toList();
      }
    } catch (e) {
      print('Error al obtener enfermeros: $e');
    }
    return [];
  }

  static Future<bool> deleteUsuario(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Usuarios/Delete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Id_Usuario': id}),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Error al actualizar usuario. Código: ${response.statusCode}, Cuerpo: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error al eliminar: $e');
      return false;
    }
  }

  static Future<bool> updateUsuario(Map<String, dynamic> usuario) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Usuarios/${usuario["Id_Usuario"]}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(usuario),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Error al actualizar usuario. Código: ${response.statusCode}, Cuerpo: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error al actualizar: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> addUsuario(Map<String, dynamic> usuario) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(usuario),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body); // usuario creado con ID
      }
    } catch (e) {
      print('Error al agregar usuario: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> restablecerContrasena(Map<String, String> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Usuarios/RestablecerContrasena'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'Success': false,
          'Message': 'Error del servidor. Intente más tarde.',
        };
      }
    } catch (e) {
      return {
        'Success': false,
        'Message': 'Error de conexión. Verifique su red.',
      };
    }
  }
}