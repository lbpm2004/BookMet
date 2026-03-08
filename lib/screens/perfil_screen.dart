import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:image_picker/image_picker.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  bool _isSaving = false;
  String _fotoUrl = ''; 
  File? _imagenSeleccionada; // Para guardar la foto nueva antes de subirla
  
  // Contadores de historial
  int _totalIntercambios = 0;
  int _aprobadas = 0;
  int _rechazadas = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Carga los datos actuales del usuario desde Firebase
  Future<void> _cargarDatos() async {
    if (user != null) {
      _correoController.text = user!.email ?? '';
      
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nombreController.text = data['nombre'] ?? '';
            _apellidoController.text = data['apellido'] ?? '';
            _cedulaController.text = data['cedula'] ?? '';
            _fotoUrl = data['fotoPerfil'] ?? '';
            
            _totalIntercambios = data['totalIntercambios'] ?? 0;
            _aprobadas = data['aprobadas'] ?? 0;
            _rechazadas = data['rechazadas'] ?? 0;
          });
        }
      } catch (e) {
        debugPrint("Error cargando datos: $e");
      }
    }
  }

  // --- LÓGICA PARA ELEGIR FOTO ---
  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('Elegir de la Galería'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                if (image != null) setState(() => _imagenSeleccionada = File(image.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.orange),
              title: const Text('Tomar Foto Nueva'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                if (image != null) setState(() => _imagenSeleccionada = File(image.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA PARA SUBIR FOTO A FIREBASE STORAGE ---
  Future<String?> _subirFotoAFirebaseStorage() async {
    if (_imagenSeleccionada == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('usuarios')
          .child(user!.uid)
          .child('perfil.jpg');

      UploadTask uploadTask = storageRef.putFile(_imagenSeleccionada!);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error subiendo foto: $e");
      return null;
    }
  }

  // Guarda los cambios en Firebase (Texto e Imagen)
  Future<void> _guardarCambios() async {
    setState(() => _isSaving = true);
    
    try {
      String? nuevaFotoUrl;
      
      // 1. Si eligió una foto nueva, la subimos a Storage
      if (_imagenSeleccionada != null) {
        nuevaFotoUrl = await _subirFotoAFirebaseStorage();
      }

      // 2. Preparamos los datos de texto a actualizar
      Map<String, dynamic> datosAActualizar = {
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'cedula': _cedulaController.text.trim(),
      };

      // 3. Si subimos una foto con éxito, la añadimos a los datos a actualizar
      if (nuevaFotoUrl != null) {
        datosAActualizar['fotoPerfil'] = nuevaFotoUrl;
      }

      // 4. Actualizamos Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update(datosAActualizar);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Perfil actualizado con éxito! ✅'), backgroundColor: Colors.green),
      );

      // Actualizamos la vista local si hubo cambio de foto
      if (nuevaFotoUrl != null) {
        setState(() {
          _fotoUrl = nuevaFotoUrl!;
          _imagenSeleccionada = null; // Limpiamos la selección
        });
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Construye las tarjetitas pequeñas del historial
  Widget _buildStatCard(String title, String count, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12), 
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)), 
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- FOTO DE PERFIL ---
                      Center(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.orange[100]!, width: 4),
                              ),
                              child: CircleAvatar(
                                radius: 45, 
                                backgroundColor: Colors.orange[50],
                                // Muestra la foto seleccionada, o si no, la de Firebase, o icono
                                backgroundImage: _imagenSeleccionada != null
                                    ? FileImage(_imagenSeleccionada!)
                                    : (_fotoUrl.isNotEmpty ? NetworkImage(_fotoUrl) : null) as ImageProvider?,
                                child: (_imagenSeleccionada == null && _fotoUrl.isEmpty)
                                    ? Icon(Icons.person, size: 45, color: Colors.orange[400])
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _seleccionarImagen, // ¡VUELVE A FUNCIONAR!
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.orange),
                              label: const Text('Cambiar Foto', style: TextStyle(color: Colors.orange, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // --- HISTORIAL ---
                      const Text('Historial de Intercambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard('Total', '$_totalIntercambios', Colors.blue),
                          _buildStatCard('Aprobadas', '$_aprobadas', Colors.green),
                          _buildStatCard('Rechazadas', '$_rechazadas', Colors.red),
                        ],
                      ),
                      
                      const SizedBox(height: 24), 

                      // --- FORMULARIO DE DATOS ---
                      const Text('Editar mis datos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),

                      // Nombre
                      TextField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: const Icon(Icons.person_outline, size: 22),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16), 

                      // Apellido
                      TextField(
                        controller: _apellidoController,
                        decoration: InputDecoration(
                          labelText: 'Apellido',
                          prefixIcon: const Icon(Icons.person_outline, size: 22),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cédula
                      TextField(
                        controller: _cedulaController,
                        decoration: InputDecoration(
                          labelText: 'Cédula / ID',
                          prefixIcon: const Icon(Icons.badge_outlined, size: 22),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Correo
                      TextField(
                        controller: _correoController,
                        readOnly: true, 
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico (No editable)',
                          prefixIcon: const Icon(Icons.mail_outline, size: 22),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const SizedBox(height: 32), 

                      // --- BOTÓN GUARDAR ---
                      SizedBox(
                        width: double.infinity,
                        height: 50, 
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _guardarCambios, // ¡AQUÍ SE GUARDA TODO!
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          icon: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save, size: 22),
                          label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                        ),
                      ),
                      
                      const SizedBox(height: 16), 
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}