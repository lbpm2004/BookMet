import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisPublicacionesScreen extends StatelessWidget {
  const MisPublicacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Publicaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800], 
        elevation: 1,
      ),
      body: userId == null
          ? const Center(child: Text('Error: Usuario no autenticado'))
          : StreamBuilder<QuerySnapshot>(
              // Buscamos en 'publicaciones' solo los libros de este usuario
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('usuarioId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Aún no has publicado ningún material.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }

                final publicaciones = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: publicaciones.length,
                  itemBuilder: (context, index) {
                    var libro = publicaciones[index].data() as Map<String, dynamic>;
                    
                    String titulo = libro['titulo'] ?? 'Libro sin título';
                    String materia = libro['materias'] ?? 'Sin materia';
                    String estado = libro['estado'] ?? 'PAUSADO';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.book, color: Colors.orange),
                        ),
                        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(materia, style: TextStyle(color: Colors.grey[600])),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: estado == 'DISPONIBLE' ? Colors.green[50] : Colors.amber[50],
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(
                            estado, 
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: estado == 'DISPONIBLE' ? Colors.green[700] : Colors.amber[800])
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}