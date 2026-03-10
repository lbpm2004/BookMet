import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/auth_service.dart';
import 'catalogo_screen.dart'; 
import 'mis_solicitudes_screen.dart';
import 'publicar_screen.dart';
import 'mis_publicaciones_screen.dart'; 
import 'perfil_screen.dart';
import 'lista_deseos_screen.dart';

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({Key? key}) : super(key: key);

  @override
  _UsuarioScreenState createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  
  // El índice 0 ahora será el Catálogo
  int _indiceSeleccionado = 0; 

  void _onItemTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }

  void _cerrarSesion() async {
    await _authService.cerrarSesion();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login'); 
  }

  // Cuerpo dinámico: Índice 0: Catálogo, Índice 1: Publicar, Índice 2: Solicitudes
  Widget _obtenerCuerpoPantalla() {
    switch (_indiceSeleccionado) {
      case 0: return const CatalogoScreen(); 
      case 1: return const PublicarScreen();
      case 2: return const MisSolicitudesScreen(); 
      default: return const CatalogoScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- TU APPBAR ORIGINAL INTACATA ---
      appBar: AppBar(
        title: const Text('BookMet', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/donar');
            },
            icon: const Icon(Icons.favorite, color: Colors.orange, size: 20),
            label: const Text(
              'DONAR',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(width: 8), 
        ],
      ),
      
      // --- TU MENÚ LATERAL (DRAWER) ORIGINAL INTACTO ---
      drawer: Drawer(
        child: user == null
            ? const Center(child: Text('No hay usuario activo'))
            : StreamBuilder<DocumentSnapshot>( 
                stream: FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
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
                            Flexible(child: Text('$nombre $apellido', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.6))),
                              child: Text(rol, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        accountEmail: Text(email),
                        currentAccountPicture: Material(
                          color: Colors.transparent, 
                          child: InkWell(
                            customBorder: const CircleBorder(), 
                            splashColor: Colors.white.withOpacity(0.5), 
                            highlightColor: Colors.orange.withOpacity(0.3), 
                            onTap: () {
                              Navigator.pop(context); 
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
                            },
                            child: Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                backgroundImage: fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                                child: fotoUrl.isEmpty ? Icon(Icons.person, size: 40, color: Colors.orange[300]) : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.redAccent),
                        title: const Text('Mi Lista de Deseos'),
                        onTap: () {
                          Navigator.pop(context); 
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaDeseosScreen()));
                        },
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
                          // En la nueva estructura, Solicitudes es el índice 2
                          setState(() => _indiceSeleccionado = 2);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings, color: Colors.grey),
                        title: const Text('Configuración'),
                        onTap: () => Navigator.pop(context),
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
      
      // --- BARRA INFERIOR MODIFICADA (Solo 3 botones) ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Catálogo'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Solicitudes'),
        ],
      ),
    );
  }
}