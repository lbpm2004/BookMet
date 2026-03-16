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
import 'perfil_screen.dart'; // NUEVO: Importamos la pantalla de perfil
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> _procesarSolicitudPrestamo(String solicitudId, String libroId, String nuevoEstado) async {
    try {
      await FirebaseFirestore.instance.collection('solicitudes').doc(solicitudId).update({
        'estadoSolicitud': nuevoEstado,
      });

      String estadoLibro = (nuevoEstado == 'ACEPTADO') ? 'PRESTADO' : 'DISPONIBLE';
      await FirebaseFirestore.instance.collection('publicaciones').doc(libroId).update({
        'estado': estadoLibro,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud $nuevoEstado'), backgroundColor: nuevoEstado == 'ACEPTADO' ? Colors.green : Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _marcarComoDevuelto(String solicitudId, String libroId, String solicitanteId) async {
    try {
      await FirebaseFirestore.instance.collection('solicitudes').doc(solicitudId).update({
        'estadoSolicitud': 'DEVUELTO',
        'fechaDevolucion': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('publicaciones').doc(libroId).update({
        'estado': 'DISPONIBLE',
      });

      if (solicitanteId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('usuarios').doc(solicitanteId).update({
          'librosDevueltos': FieldValue.increment(1),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Libro recibido en biblioteca 📚✅'), backgroundColor: const Color(0xFF1859A9)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al devolver: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _construirVistaInicio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings, size: 100, color: Colors.red[800]),
          const SizedBox(height: 20),
          Text('Panel de Control', style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.bold)
          ),
          const Text('Modo Administrador Activo', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _construirVentanaSolicitudes() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.fact_check), text: 'Nuevos Libros'),
              Tab(icon: Icon(Icons.library_books), text: 'Gestión Préstamos'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Mis Solicitudes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _construirListaModeracion(),
                _construirListaSolicitudesGlobales(),
                const MisSolicitudesScreen(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _construirListaModeracion() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('publicaciones')
          .where('estado', whereIn: ['PENDIENTE', 'Pendiente'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.red));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _vistaVacia('No hay libros por moderar');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var libro = doc.data() as Map<String, dynamic>;
            return _tarjetaModeracion(doc.id, libro);
          },
        );
      },
    );
  }

  Widget _construirListaSolicitudesGlobales() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.red));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _vistaVacia('No hay pedidos de libros');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var sol = doc.data() as Map<String, dynamic>;
            String estado = sol['estadoSolicitud'] ?? 'PENDIENTE';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.person_search, color: Colors.red),
                title: Text(sol['tituloLibro'] ?? 'Libro pedido'),
                subtitle: Text('Estado: $estado'),
                trailing: estado == 'PENDIENTE' 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _procesarSolicitudPrestamo(doc.id, sol['libroId'], 'ACEPTADO')),
                        IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _procesarSolicitudPrestamo(doc.id, sol['libroId'], 'RECHAZADO')),
                      ],
                    )
                  : estado == 'ACEPTADO'
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.assignment_return, size: 16),
                          label: const Text('Recibir', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1859A9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          ),
                          onPressed: () => _marcarComoDevuelto(doc.id, sol['libroId'], sol['solicitanteId'] ?? ''),
                        )
                      : Icon(estado == 'DEVUELTO' ? Icons.library_add_check : Icons.close, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  Widget _vistaVacia(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(mensaje, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _tarjetaModeracion(String docId, Map<String, dynamic> libro) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(libro['fotoUrl'] ?? '', width: 70, height: 90, fit: BoxFit.cover, 
                errorBuilder: (c, e, s) => Container(width: 70, height: 90, color: Colors.grey[300], child: const Icon(Icons.book))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(libro['titulo'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(libro['autor'] ?? 'Autor desconocido', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Estado: ${libro['estadoFisico']?.toString().toUpperCase() ?? 'NO ESPECIFICADO'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  if (libro['detallesFisicos'] != null && libro['detallesFisicos'].toString().trim().isNotEmpty)
                    Text('Detalles: ${libro['detallesFisicos']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _gestionarPublicacion(docId, libro['usuarioId'], 'RECHAZADO')),
                      IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _gestionarPublicacion(docId, libro['usuarioId'], 'DISPONIBLE')),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
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
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Colors.red[800]),
                  accountName: Text('${userData['nombre'] ?? 'Admin'} ${userData['apellido'] ?? ''}'),
                  accountEmail: Text(user?.email ?? ''),
                  currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, color: Colors.red)),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.redAccent), 
                  title: const Text('Mi Lista de Deseos'), 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaDeseosScreen()))
                ),
                ListTile(
                  leading: const Icon(Icons.book, color: Colors.orange), 
                  title: const Text('Mis Publicaciones'), 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MisPublicacionesScreen()))
                ),
                ListTile(
                  leading: const Icon(Icons.volunteer_activism, color: Colors.green), 
                  title: const Text('Donar a Biblioteca'), 
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.pushNamed(context, '/donar');
                  }
                ),
                const Divider(),
                // NUEVO: Botón de Gestionar Usuario añadido en el Admin Screen
                ListTile(
                  leading: const Icon(Icons.manage_accounts, color: Colors.red),
                  title: const Text('Gestionar Usuario'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
                  },
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red), 
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), 
                  onTap: _cerrarSesion
                ),
              ],
            );
          },
        ),
      ),
      body: _obtenerCuerpoPantalla(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaDeseosScreen())),
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.favorite, color: Colors.red, size: 30),
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