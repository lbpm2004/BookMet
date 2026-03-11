import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisPublicacionesScreen extends StatefulWidget {
  const MisPublicacionesScreen({super.key});

  @override
  State<MisPublicacionesScreen> createState() => _MisPublicacionesScreenState();
}

class _MisPublicacionesScreenState extends State<MisPublicacionesScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  final List<String> _carreras = ['Ingenieria', 'Psicologia', 'Derecho', 'Administracion'];
  final List<String> _materias = ['Matemáticas 1', 'Matemáticas 2', 'Matemáticas 5', 'Física'];

  // Función para confirmar y eliminar una publicación
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

  // Ventana emergente para editar Carrera y Materia
  void _mostrarDialogoEdicion(String docId, String carreraActual, String materiaActual) {
    String? nuevaCarrera = _carreras.contains(carreraActual) ? carreraActual : null;
    String? nuevaMateria = _materias.contains(materiaActual) ? materiaActual : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Clasificación', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Al guardar los cambios, la publicación pasará a estado PAUSADO y será enviada a revisión.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: nuevaCarrera,
                    decoration: const InputDecoration(labelText: 'Carrera', border: OutlineInputBorder()),
                    items: _carreras.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setStateDialog(() => nuevaCarrera = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: nuevaMateria,
                    decoration: const InputDecoration(labelText: 'Materia', border: OutlineInputBorder()),
                    items: _materias.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setStateDialog(() => nuevaMateria = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () async {
                    if (nuevaCarrera != null && nuevaMateria != null) {
                      // Actualizamos y pausamos
                      await FirebaseFirestore.instance.collection('publicaciones').doc(docId).update({
                        'carrera': nuevaCarrera,
                        'materia': nuevaMateria,
                        'estado': 'PAUSADO',
                      });
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cambios guardados. Publicación en revisión.'), backgroundColor: Colors.orange),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
                  child: const Text('GUARDAR Y PAUSAR', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
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
        // Buscamos SOLO las publicaciones creadas por este usuario
        stream: FirebaseFirestore.instance
            .collection('publicaciones')
            .where('usuarioId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar tus publicaciones.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
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
              String carreraActual = libroData['carrera'] ?? '';
              String materiaActual = libroData['materia'] ?? '';

              return _HoverMiPublicacionCard(
                libroData: libroData,
                onEdit: () => _mostrarDialogoEdicion(idDoc, carreraActual, materiaActual),
                onDelete: () => _confirmarEliminacion(idDoc),
              );
            },
          );
        },
      ),
    );
  }
}

// --- WIDGET PARA ANIMAR Y MOSTRAR OPCIONES (HOVER) ---
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
    String estado = widget.libroData['estado'] ?? 'DESCONOCIDO';
    
    // Asignar colores según el estado
    Color colorEstado = Colors.grey;
    if (estado == 'DISPONIBLE') colorEstado = Colors.green;
    if (estado == 'RESERVADO') colorEstado = Colors.blue;
    if (estado == 'PAUSADO') colorEstado = Colors.orange;

    return MouseRegion(
      cursor: SystemMouseCursors.basic, 
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.05 : 1.0, 
        duration: const Duration(milliseconds: 200), 
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _isHovering ? Colors.black26 : Colors.black12, 
                blurRadius: _isHovering ? 12 : 4,
                offset: Offset(0, _isHovering ? 4 : 2),
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
              
              // ETIQUETA DE ESTADO (Arriba a la izquierda)
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
                    estado,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // BOTÓN DE OPCIONES (Arriba a la derecha)
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
                      child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Editar Clasificación')]),
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