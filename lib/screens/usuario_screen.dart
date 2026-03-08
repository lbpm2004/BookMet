import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/auth_service.dart';
import 'catalogo_screen.dart'; 
import 'publicar_screen.dart';
import 'mis_publicaciones_screen.dart'; 

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({Key? key}) : super(key: key);

  @override
  _UsuarioScreenState createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  
  int _indiceSeleccionado = 0; 

  // Cambia el índice seleccionado cuando tocas un botón de la barra inferior
  void _onItemTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }

  // Cierra sesión y devuelve al usuario a la pantalla de login/bienvenida
  void _cerrarSesion() async {
    await _authService.cerrarSesion();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login'); 
  }

  // Decide qué "cuerpo" mostrar según el botón de abajo que esté activo
  Widget _obtenerCuerpoPantalla() {
    switch (_indiceSeleccionado) {
      case 0:
        return const CatalogoScreen(); 
      case 1:
        return const PublicarScreen();
      default:
        return const CatalogoScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookMet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
      ),
      
      // --- MENÚ LATERAL (DRAWER) INTEGRADO ---
      drawer: Drawer(
        child: user == null
            ? const Center(child: Text('No hay usuario activo'))
            : FutureBuilder<DocumentSnapshot>(
                // Buscamos los datos del usuario actual en Firestore
                future: FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Error al cargar datos del perfil'));
                  }

                  // Extraemos los datos de la base de datos
                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  String nombre = userData['nombre'] ?? 'Usuario';
                  String apellido = userData['apellido'] ?? '';
                  String email = userData['email'] ?? '';
                  String rol = userData['rol'] ?? 'ESTUDIANTE';
                  String fotoUrl = userData['fotoPerfil'] ?? '';

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // --- CABECERA DEL MENÚ MEJORADA ---
                      UserAccountsDrawerHeader(
                        decoration: BoxDecoration(color: Colors.orange[800]),
                        
                        // DISEÑO NUEVO: Nombre y Rol en la misma línea
                        accountName: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$nombre $apellido', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10), // Espacio entre nombre y rol
                            
                            // La nueva "Píldora" elegante para el Rol
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25), 
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.6)),
                              ),
                              child: Text(
                                rol, 
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  letterSpacing: 0.5
                                ),
                              ),
                            ),
                          ],
                        ),
                        accountEmail: Text(email),
                        
                        // Foto de perfil
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                          child: fotoUrl.isEmpty ? Icon(Icons.person, size: 40, color: Colors.orange[300]) : null,
                        ),
                      ),
                      
                      // --- OPCIONES DEL MENÚ LATERAL ---
                      ListTile(
                        leading: const Icon(Icons.book, color: Colors.orange),
                        title: const Text('Mis Publicaciones'),
                        onTap: () {
                          // 1. Cerramos el menú lateral
                          Navigator.pop(context); 
                          // 2. Navegamos a la pantalla de Mis Publicaciones
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MisPublicacionesScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.handshake, color: Colors.orange),
                        title: const Text('Intercambios y Solicitudes'),
                        onTap: () {
                          // Aquí conectaremos la pantalla de transacciones en el futuro
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings, color: Colors.grey),
                        title: const Text('Configuración'),
                        onTap: () {
                           Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        onTap: _cerrarSesion,
                      ),
                    ],
                  );
                },
              ),
      ),
      
      // --- CUERPO Y BARRA INFERIOR ---
      body: _obtenerCuerpoPantalla(),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Publicar',
          ),
        ],
      ),
    );
  }
}