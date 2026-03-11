import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/auth_service.dart';
import 'catalogo_screen.dart'; 
import 'gestionar_baneos_screen.dart'; 
import 'mis_solicitudes_screen.dart'; 
import 'publicar_screen.dart';
import 'lista_deseos_screen.dart';
import 'mis_publicaciones_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  
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

  // --- LÓGICA DE TRANSACCIONES ORIGINAL INTACTA ---
  Future<void> _gestionarPublicacion(String publicacionId, String usuarioId, String nuevoEstado) async {
    try {
      final publicacionRef = FirebaseFirestore.instance.collection('publicaciones').doc(publicacionId);
      final usuarioRef = FirebaseFirestore.instance.collection('usuarios').doc(usuarioId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(publicacionRef, {'estado': nuevoEstado});

        if (nuevoEstado == 'DISPONIBLE') {
          transaction.update(usuarioRef, {
            'aprobadas': FieldValue.increment(1),
            'totalIntercambios': FieldValue.increment(1),
          });
        } else if (nuevoEstado == 'RECHAZADO') {
          transaction.update(usuarioRef, {
            'rechazadas': FieldValue.increment(1),
            'totalIntercambios': FieldValue.increment(1),
          });
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoEstado == 'DISPONIBLE' ? 'Libro Aprobado ✅' : 'Libro Rechazado ❌'), 
          backgroundColor: nuevoEstado == 'DISPONIBLE' ? Colors.green : Colors.red
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // --- VISTAS DEL ADMIN ORIGINALES ---
  Widget _construirVistaInicio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings, size: 100, color: Colors.red[800]),
          const SizedBox(height: 20),
          const Text('Panel de Control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Modo Administrador Activo', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _construirVentanaSolicitudes() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(icon: Icon(Icons.fact_check), text: 'Por Moderar'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Mis Intercambios')
          ],
          ),
          Expanded(child: TabBarView(children: [
            _construirListaModeracion(),
            const MisSolicitudesScreen()
          ]))
        ],
      )
      );
  }

  Widget _construirListaModeracion() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('publicaciones')
          .where('estado', isEqualTo: 'Pendiente')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.red));
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Todo al día', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Text('No hay publicaciones pendientes por revisar.', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var libro = doc.data() as Map<String, dynamic>;
            
            String titulo = libro['titulo'] ?? 'Sin título';
            String autor = libro['autor'] ?? 'Autor desconocido';
            String materia = libro['materia'] ?? 'Sin materia';
            String fotoUrl = libro['fotoUrl'] ?? 'https://via.placeholder.com/150';
            String usuarioId = libro['usuarioId'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        fotoUrl,
                        width: 80,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80, height: 110, color: Colors.grey[300],
                          child: const Icon(Icons.book, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(autor, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Materia: $materia', style: TextStyle(color: Colors.red[800], fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                                onPressed: () => _gestionarPublicacion(doc.id, usuarioId, 'RECHAZADO'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                                onPressed: () => _gestionarPublicacion(doc.id, usuarioId, 'DISPONIBLE'), 
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _construirGestionUsuarios() {
    return const GestionarBaneosScreen();
  }

  Widget _obtenerCuerpoPantalla() {
    switch (_indiceSeleccionado) {
      case 0: return _construirVistaInicio();
      case 1: return const CatalogoScreen(); 
      case 2: return const PublicarScreen(); 
      case 3: return _construirVentanaSolicitudes();
      case 4: return _construirGestionUsuarios();
      default: return _construirVistaInicio();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookMet Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: user == null ? const Center(child: Text('No hay usuario activo')) : StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar datos del usuario'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.red));
            }

            String nombre = 'Administrador';
            String apellido = '';
            String email = user?.email ?? '';

            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              nombre = userData['nombre'] ?? 'Administrador';
              apellido = userData['apellido'] ?? '';
              email = userData['email'] ?? user?.email ?? '';
            }
            
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Colors.red[800]),
                  accountName: Text('$nombre $apellido'.trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(email),
                  currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.red)),
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
                const Divider(),

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
      
      // --- CORAZONCITO FLOTANTE FIJADO ABAJO A LA DERECHA ---
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // <- ESTO LO ANCLA ABAJO A LA DERECHA
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaDeseosScreen()));
        },
        backgroundColor: Colors.white,
        elevation: 6, // Un poco más de sombra para que resalte
        shape: const CircleBorder(), // Hace que el botón sea perfectamente redondo
        tooltip: 'Ver Lista de Deseos',
        child: const Icon(Icons.favorite, color: Colors.red, size: 30), // Ícono un poco más grande
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: _onItemTapped,
        selectedItemColor: Colors.red[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Catálogo'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Publicar'), 
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: 'Solicitudes'),
          BottomNavigationBarItem(icon: Icon(Icons.group_remove), label: 'Usuarios'),
        ],
      ),
    );
  }
}