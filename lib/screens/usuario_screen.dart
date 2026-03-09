import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/auth_service.dart';
import 'catalogo_screen.dart'; 
import 'mis_solicitudes_screen.dart';
import 'publicar_screen.dart';
import 'mis_publicaciones_screen.dart'; 
import 'perfil_screen.dart';
import 'lista_deseos_screen.dart'; // <-- ¡AQUÍ IMPORTAMOS LA NUEVA PANTALLA!

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({Key? key}) : super(key: key);

  @override
  _UsuarioScreenState createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
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

  // Función para dar/quitar like a un libro
  void _alternarFavorito(String pubId, bool esFavorito) async {
    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user!.uid);
    if (esFavorito) {
      // Si ya es favorito, lo quitamos
      await docRef.update({'favoritos': FieldValue.arrayRemove([pubId])});
    } else {
      // Si no es favorito, lo agregamos
      await docRef.update({'favoritos': FieldValue.arrayUnion([pubId])});
    }
  }

  // --- VISTA DE INICIO (CON CORAZONCITOS) ---
  Widget _construirVistaInicio() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '¿Buscas un libro en concreto? Empieza buscando aquí',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
        ),
        
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Últimas publicaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),

        Expanded(
          // 1. PRIMERO ESCUCHAMOS AL USUARIO (Para saber cuáles son sus favoritos en tiempo real)
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));
              
              // Extraemos la lista de favoritos (si no existe, creamos una lista vacía)
              List<dynamic> misFavoritos = userSnapshot.data!.data().toString().contains('favoritos') 
                  ? userSnapshot.data!.get('favoritos') 
                  : [];

              // 2. LUEGO ESCUCHAMOS LOS LIBROS
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('publicaciones').limit(15).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Aún no hay publicaciones en la app.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var publicacion = doc.data() as Map<String, dynamic>;
                      String pubId = doc.id; // ¡Necesitamos el ID del libro!
                      String titulo = publicacion['titulo'] ?? 'Sin título';
                      String autor = publicacion['autor'] ?? 'Autor desconocido';

                      // Comprobamos si este libro está en mi lista
                      bool esFavorito = misFavoritos.contains(pubId);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.book, color: Colors.white),
                          ),
                          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(autor),
                          // EL BOTÓN DEL CORAZÓN
                          trailing: IconButton(
                            icon: Icon(
                              esFavorito ? Icons.favorite : Icons.favorite_border,
                              color: esFavorito ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _alternarFavorito(pubId, esFavorito),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _obtenerCuerpoPantalla() {
    switch (_indiceSeleccionado) {
      case 0: return _construirVistaInicio();
      case 1: return const CatalogoScreen(); 
      case 2: return const PublicarScreen();
      case 3: return const MisSolicitudesScreen(); 
      default: return _construirVistaInicio();
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
        actions: [
          TextButton.icon(
            onPressed: () {
              // Navega a la pantalla de donación que creamos anteriormente
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
          const SizedBox(width: 8), // Espaciado final
        ],
      ),
      
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
                      
                      // NUEVO BOTÓN: LISTA DE DESEOS ❤️
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
                          setState(() => _indiceSeleccionado = 3);
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
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange[800],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Catálogo'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Solicitudes'),
        ],
      ),
    );
  }
}