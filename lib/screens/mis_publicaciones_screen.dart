import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'publicar_screen.dart';

class MisPublicacionesScreen extends StatefulWidget {
  const MisPublicacionesScreen({super.key});

  @override
  State<MisPublicacionesScreen> createState() => _MisPublicacionesScreenState();
}

class _MisPublicacionesScreenState extends State<MisPublicacionesScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Función para confirmar y eliminar una publicación (TU LÓGICA INTACTA)
  void _confirmarEliminacion(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar publicación?'),
        content: const Text('Esta acción es irreversible y el libro desaparecerá del catálogo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('publicaciones').doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicación eliminada.'), backgroundColor: Colors.red),
              );
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editarPublicacionCompleta(Map<String, dynamic> libroData, String docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicarScreen(
          libroAEditar: libroData,
          docId: docId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Publicaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('publicaciones')
            .where('usuarioId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar tus publicaciones.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.red[800]));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aún no has subido ningún libro.'));
          }

          var libros = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180, 
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.60, 
            ),
            itemCount: libros.length,
            itemBuilder: (context, index) {
              var libroData = libros[index].data() as Map<String, dynamic>;
              String idDoc = libros[index].id;

              return _HoverMiPublicacionCard(
                libroData: libroData,
                onEdit: () => _editarPublicacionCompleta(libroData, idDoc),
                onDelete: () => _confirmarEliminacion(idDoc),
              );
            },
          );
        },
      ),
    );
  }
}

class _HoverMiPublicacionCard extends StatefulWidget {
  final Map<String, dynamic> libroData;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HoverMiPublicacionCard({required this.libroData, required this.onEdit, required this.onDelete});

  @override
  State<_HoverMiPublicacionCard> createState() => _HoverMiPublicacionCardState();
}

class _HoverMiPublicacionCardState extends State<_HoverMiPublicacionCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    String estado = (widget.libroData['estado'] ?? 'PENDIENTE').toString().toUpperCase();
    
    Color colorEstado = Colors.grey;
    if (estado == 'DISPONIBLE') colorEstado = Colors.green;
    if (estado == 'RESERVADO') colorEstado = Colors.blue;
    if (estado == 'PENDIENTE') colorEstado = Colors.orange;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.05 : 1.0, 
        duration: const Duration(milliseconds: 200), 
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _isHovering ? Colors.black26 : Colors.black12, 
                blurRadius: _isHovering ? 12 : 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        widget.libroData['fotoUrl'] ?? 'https://via.placeholder.com/150',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.libroData['titulo'] ?? 'Sin título',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorEstado.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estado == 'PENDIENTE' ? 'EN REVISIÓN' : estado,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  icon: Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                    child: const Icon(Icons.more_vert, size: 20, color: Colors.black),
                  ),
                  onSelected: (value) {
                    if (value == 'editar') widget.onEdit();
                    if (value == 'eliminar') widget.onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Editar Libro')]),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Eliminar')]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}