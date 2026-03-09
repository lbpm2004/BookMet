import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListaDeseosScreen extends StatefulWidget {
  const ListaDeseosScreen({super.key});

  @override
  State<ListaDeseosScreen> createState() => _ListaDeseosScreenState();
}

class _ListaDeseosScreenState extends State<ListaDeseosScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Función para quitar un libro de favoritos directamente desde esta pantalla
  void _quitarDeFavoritos(String pubId) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
      'favoritos': FieldValue.arrayRemove([pubId])
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Libro eliminado de tu lista 💔'), backgroundColor: Colors.redAccent, duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mi Lista de Deseos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
      ),
      // Usamos un StreamBuilder para escuchar los favoritos del usuario en tiempo real
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).snapshots(),
        builder: (context, snapshotUsuario) {
          if (snapshotUsuario.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshotUsuario.hasData || !snapshotUsuario.data!.exists) {
            return const Center(child: Text('Error al cargar tu lista.'));
          }

          // Obtenemos la lista de IDs de los libros favoritos
          List<dynamic> favoritos = snapshotUsuario.data!.get('favoritos') ?? [];

          if (favoritos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Aún no tienes libros en tu lista', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Toca el corazón en los libros que te gusten', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favoritos.length,
            itemBuilder: (context, index) {
              String pubId = favoritos[index];

              // Por cada ID, buscamos los datos del libro en la colección 'publicaciones'
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('publicaciones').doc(pubId).get(),
                builder: (context, snapshotPublicacion) {
                  if (snapshotPublicacion.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(title: Text('Cargando libro...')),
                    );
                  }

                  if (!snapshotPublicacion.hasData || !snapshotPublicacion.data!.exists) {
                    return const SizedBox.shrink(); // Si el libro fue borrado de la app, no mostramos nada
                  }

                  var publicacion = snapshotPublicacion.data!.data() as Map<String, dynamic>;
                  String titulo = publicacion['titulo'] ?? 'Sin título';
                  String autor = publicacion['autor'] ?? 'Autor desconocido';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orangeAccent,
                        child: Icon(Icons.menu_book, color: Colors.white),
                      ),
                      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(autor),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _quitarDeFavoritos(pubId), // Al tocar, lo borra
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}