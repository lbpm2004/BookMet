import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/auth_service.dart';
import 'catalogo_screen.dart'; 
import 'mis_solicitudes_screen.dart';
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

  // --- NUEVA VISTA DE INICIO (Index 0) ---
  Widget _construirVistaInicio() {
    return Column(
      children: [
        // 1. Barra de Búsqueda
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '¿Buscas un libro en concreto? Empieza buscando aquí',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            onSubmitted: (value) {
              // Aquí en el futuro puedes hacer que al buscar lo mande al Catálogo con el filtro
            },
          ),
        ),
        
        // 2. Título de la sección
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Últimas publicaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // 3. Lista de los últimos 15 libros
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Consulta a Firestore: Trae 15 documentos de la colección 'publicaciones'
            // (Si tienes un campo de fecha de creación, podrías agregar .orderBy('fecha', descending: true) antes del limit)
            stream: FirebaseFirestore.instance.collection('publicaciones').limit(15).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.orange));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Aún no hay publicaciones en la app.'));
              }

              // Construimos la lista con las tarjetas de los libros
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var publicacion = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  
                  // NOTA: Ajusta 'titulo' y 'autor' si tus campos en Firebase se llaman distinto
                  String titulo = publicacion['titulo'] ?? 'Sin título';
                  String autor = publicacion['autor'] ?? 'Autor desconocido';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orangeAccent,
                        child: Icon(Icons.book, color: Colors.white),
                      ),
                      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(autor),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Decide qué "cuerpo" mostrar según el botón
  Widget _obtenerCuerpoPantalla() {
    switch (_indiceSeleccionado) {
      case 0:
        return _construirVistaInicio(); // Tu nueva pantalla de bienvenida interactiva
      case 1:
        return const CatalogoScreen(); 
      case 2:
        return const PublicarScreen();
      case 3:
        return const MisSolicitudesScreen(); 
      default:
        return _construirVistaInicio();
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
      
      // --- MENÚ LATERAL (DRAWER) ---
      drawer: Drawer(
        child: user == null
            ? const Center(child: Text('No hay usuario activo'))
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Error al cargar datos del perfil'));
                  }

                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  String nombre = userData['nombre'] ?? 'Usuario';
                  String apellido = userData['apellido'] ?? '';
                  String email = userData['email'] ?? '';
                  String rol = userData['rol'] ?? 'ESTUDIANTE';
                  String fotoUrl = userData['fotoPerfil'] ?? '';

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      UserAccountsDrawerHeader(
                        decoration: BoxDecoration(color: Colors.orange[800]),
                        accountName: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$nombre $apellido', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25), 
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.6)),
                              ),
                              child: Text(
                                rol, 
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        accountEmail: Text(email),
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                          child: fotoUrl.isEmpty ? Icon(Icons.person, size: 40, color: Colors.orange[300]) : null,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.book, color: Colors.orange),
                        title: const Text('Mis Publicaciones'),
                        onTap: () {
                          Navigator.pop(context); 
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MisPublicacionesScreen()));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.handshake, color: Colors.orange),
                        title: const Text('Intercambios y Solicitudes'),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _indiceSeleccionado = 3; 
                          });
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
      
      body: _obtenerCuerpoPantalla(),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Publicar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), 
            label: 'Solicitudes',
          ),
        ],
      ),
    );
  }
}