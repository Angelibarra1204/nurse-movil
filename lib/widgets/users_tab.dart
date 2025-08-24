import 'package:flutter/material.dart';
import '../services/api.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({Key? key}) : super(key: key);

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<Map<String, dynamic>> enfermeros = [];
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _fetchEnfermeros();
  }

  Future<void> _fetchEnfermeros() async {
    final result = await Api.getEnfermeros();
    setState(() {
      enfermeros = result;
    });
  }

  void _showForm({Map<String, dynamic>? usuario}) {
    final isEditing = usuario != null;
    final _nombreController = TextEditingController(text: usuario?['Nombre']);
    final _apellidosController = TextEditingController(text: usuario?['Apellidos']);
    final _correoController = TextEditingController(text: usuario?['Correo']);
    final _telefonoController = TextEditingController(text: usuario?['Telefono']);
    final _contrasenaController = TextEditingController();
    String _estadoSeleccionado = usuario?['Estado'] ?? 'Habilitado';

    // final _especialidadController = TextEditingController(
    //   text: (usuario?['Enfermeros'] != null && usuario!['Enfermeros'].isNotEmpty)
    //       ? usuario['Enfermeros'][0]['Especialidad']
    //       : '',
    // );
    final _respuestaSeguridadController = TextEditingController(text: usuario?['Respuesta_seguridad'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Editar Enfermero' : 'Nuevo Enfermero'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: _apellidosController, decoration: const InputDecoration(labelText: 'Apellidos')),
              TextField(controller: _correoController, decoration: const InputDecoration(labelText: 'Correo')),
              TextField(controller: _contrasenaController, decoration: const InputDecoration(labelText: 'Contraseña')),
              TextField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono')),
              DropdownButtonFormField<String>(
                value: _estadoSeleccionado,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: ['Habilitado', 'Deshabilitado']
                    .map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        ))
                    .toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    _estadoSeleccionado = valor;
                  }
                },
              ),
              // TextField(controller: _especialidadController, decoration: const InputDecoration(labelText: 'Especialidad')),
              TextField(controller: _respuestaSeguridadController, decoration: const InputDecoration(labelText: 'Respuesta de Seguridad'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final now = DateTime.now().toIso8601String();

              if (isEditing) {
                final editarUsuario = <String, dynamic>{
                  'Id_Usuario': usuario!['Id_Usuario'],
                  'Nombre': _nombreController.text,
                  'Apellidos': _apellidosController.text,
                  'Correo': _correoController.text,
                  'Contrasena': _contrasenaController.text,
                  'Telefono': _telefonoController.text,
                  'Fecha_registro': usuario['Fecha_registro'],
                  'Estado': _estadoSeleccionado,
                  'Tipo_usuario': 'Enfermero',
                  'Enfermeros': [
                    {
                      'Id_Enfermero': (usuario['Enfermeros'].isNotEmpty)
                          ? usuario['Enfermeros'][0]['Id_Enfermero']
                          : 0,
                      'Especialidad': "Cardiología",
                      'Id_Usuario': usuario['Id_Usuario'],
                    }
                  ],
                  'Respuesta_seguridad': _respuestaSeguridadController.text,
                  'Pacientes': []
                };

                final success = await Api.updateUsuario(editarUsuario);
                if (success) {
                  Navigator.pop(context);
                  _fetchEnfermeros();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al actualizar el usuario')),
                  );
                }
              } else {
                if (_contrasenaController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña es obligatoria al crear un usuario')),
                  );
                  return;
                }

                final nuevoUsuarioBase = {
                  'Nombre': _nombreController.text,
                  'Apellidos': _apellidosController.text,
                  'Correo': _correoController.text,
                  'Contrasena': _contrasenaController.text,
                  'Telefono': _telefonoController.text,
                  'Fecha_registro': now,
                  'Tipo_usuario': 'Enfermero',
                  'Estado': 'Habilitado',
                  'Enfermeros': [],
                  'Respuesta_seguridad': _respuestaSeguridadController.text,
                  'Pacientes': []
                };

                final usuarioCreado = await Api.addUsuario(nuevoUsuarioBase);
                if (usuarioCreado != null) {
                  final usuarioConEspecialidad = {
                    ...usuarioCreado,
                    'Enfermeros': [
                      {
                        'Id_Enfermero': 0,
                        'Especialidad': "Cardiología",
                        'Id_Usuario': usuarioCreado['Id_Usuario'],
                      }
                    ]
                  };

                  final success = await Api.updateUsuario(usuarioConEspecialidad);
                  if (success) {
                    Navigator.pop(context);
                    _fetchEnfermeros();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al asignar especialidad')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al crear el usuario')),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Guardar' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que deseas eliminar este usuario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final success = await Api.deleteUsuario(id);
              Navigator.pop(context);
              if (success) _fetchEnfermeros();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _enfermerosFiltrados {
    if (_filtroEstado == null) return enfermeros;
    return enfermeros.where((e) => e['Estado'] == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('users'),
      padding: const EdgeInsets.all(30),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '👩‍⚕️ Enfermeros',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF22543D)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
                onPressed: () => _showForm(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Apellidos')),
                  DataColumn(label: Text('Correo')),
                  DataColumn(label: Text('Teléfono')),
                  DataColumn(
                    label: InkWell(
                      onTap: () {
                        setState(() {
                          if (_filtroEstado == null) {
                            _filtroEstado = 'Habilitado';
                          } else if (_filtroEstado == 'Habilitado') {
                            _filtroEstado = 'Deshabilitado';
                          } else {
                            _filtroEstado = null;
                          }
                        });
                      },
                      child: Row(
                        children: [
                          const Text('Estado'),
                          if (_filtroEstado != null) ...[ 
                            Icon(
                              _filtroEstado == 'Habilitado' ? Icons.check_circle : Icons.cancel,
                              color: _filtroEstado == 'Habilitado' ? Colors.green : Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _filtroEstado!,
                              style: TextStyle(
                                color: _filtroEstado == 'Habilitado' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: _enfermerosFiltrados.map((e) {
                  return DataRow(cells: [
                    DataCell(Text(e['Nombre'] ?? '')),
                    DataCell(Text(e['Apellidos'] ?? '')),
                    DataCell(Text(e['Correo'] ?? '')),
                    DataCell(Text(e['Telefono'] ?? '')),
                    DataCell(Text(e['Estado'] ?? '')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showForm(usuario: e),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(e['Id_Usuario']),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
