import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ¡IMPORTANTE AÑADIR ESTO!
import '../services/auth_service.dart';

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
    Navigator.pushReplacementNamed(context, '/'); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      
      // 1. LA BARRA SUPERIOR (Sin la foto del usuario)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Row(
          children: [
            Icon(Icons.local_library_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('BOOKMET', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
      ),

      // 2. EL MENÚ LATERAL (Con Cerrar Sesión al final y foto más grande)
      drawer: Drawer(
        child: Column(
          children: [
            // Lista de opciones que ocupa todo el espacio superior disponible
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Usamos FutureBuilder para buscar el ROL en Firestore
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).get(),
                    builder: (context, snapshot) {
                      String rolTexto = 'Cargando...';
                      String nombreTexto = user?.displayName ?? 'Usuario';
                      String? urlFotoFirestore; // <-- Creamos una variable para la foto

                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        var datosUsuario = snapshot.data!.data() as Map<String, dynamic>?;
                        if (datosUsuario != null) {
                          rolTexto = datosUsuario['rol'] ?? 'ESTUDIANTE';
                          rolTexto = rolTexto[0].toUpperCase() + rolTexto.substring(1).toLowerCase();
                          nombreTexto = datosUsuario['nombre'] ?? nombreTexto;
                          // ¡Extraemos la URL de la foto directamente de Firestore!
                          urlFotoFirestore = datosUsuario['fotoPerfil'];
                        }
                      }
                      
                      // Verificamos si la variable de Firestore tiene un link válido
                      bool tieneFoto = urlFotoFirestore != null && urlFotoFirestore.isNotEmpty;

                      return DrawerHeader(
                        decoration: const BoxDecoration(color: Colors.orange),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Foto de perfil grande y segura
                            CircleAvatar(
                              radius: 40, // Tamaño grande (80px de diámetro) pero controlado
                              backgroundColor: Colors.white,
                              // Usamos la URL de Firestore en lugar de la de FirebaseAuth
                              backgroundImage: tieneFoto ? NetworkImage(urlFotoFirestore!) : null,
                              child: !tieneFoto ? const Icon(Icons.person, size: 45, color: Colors.orange) : null,
                            ),
                            const SizedBox(width: 16), // Espacio entre foto y texto
                            
                            // 2. Columna con Nombre y Rol
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombreTexto,
                                    style: const TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.bold, 
                                      color: Colors.white
                                    ),
                                    maxLines: 2, // Si el nombre es muy largo, baja a la siguiente línea
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white24, // Un fondito sutil para resaltar el rol
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      rolTexto,
                                      style: const TextStyle(
                                        fontSize: 14, 
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Mi Perfil / Mis Publicaciones'),
                    onTap: () { /* Navegar a perfil */ },
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: const Text('Mi Lista de Deseos (Wishlist)'),
                    onTap: () { /* Navegar a wishlist */ },
                  ),
                  ListTile(
                    leading: const Icon(Icons.volunteer_activism),
                    title: const Text('Donar a BookMet'),
                    onTap: () { /* Navegar a donar */ },
                  ),
                ],
              ),
            ),
            
            // Botón de Cerrar Sesión pegado estrictamente abajo
            const Divider(height: 1),
            SafeArea( // SafeArea evita que el botón quede oculto por la barra de navegación táctil del teléfono
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: _cerrarSesion,
              ),
            ),
          ],
        ),
      ),

      // 3. EL CUERPO PRINCIPAL (Feed)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buscador actualizado
            TextField(
              decoration: InputDecoration(
                hintText: '¿Qué libro estás buscando?',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30), // Espacio ajustado ya que quitamos los filtros/chips

            // Título de sección
            const Text(
              'Últimas Publicaciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Tarjetas de ejemplo (Eliminamos _buildChip y la fila de filtros)
            _buildPublicacionCard('Cálculo de una variable', 'Matemáticas I', 'Intercambio', 'Buen estado'),
            _buildPublicacionCard('Física Universitaria Vol. 1', 'Física I', 'Donación', 'Usado'),
            _buildPublicacionCard('Fundamentos de Programación', 'Programación I', 'Intercambio', 'Casi nuevo'),
          ],
        ),
      ),

      // 4. BARRA DE NAVEGACIÓN INFERIOR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceSeleccionado,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Catálogo'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 30), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Solicitudes'),
        ],
      ),
    );
  }

  // WIDGET AUXILIAR PARA LAS TARJETAS DE LIBROS
  Widget _buildPublicacionCard(String titulo, String materia, String tipo, String estado) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              height: 100,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.book, size: 40, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(materia, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tipo == 'Donación' ? Colors.green[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(tipo, style: TextStyle(fontSize: 12, color: tipo == 'Donación' ? Colors.green[800] : Colors.blue[800], fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text('• $estado', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}