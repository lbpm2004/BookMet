import 'dart:ui'; // Necesario para el filtro de difuminado
import 'package:flutter/material.dart';

class FondoConBlur extends StatelessWidget {
  final Widget child;

  const FondoConBlur({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // CAPA 1 (Fondo): La foto de la Unimet cubriendo toda la pantalla
        Positioned.fill(
          child: Image.asset(
            'assets/images/fondo_unimet.jpg', // <--- Asegúrate de que este nombre coincida con tu archivo
            fit: BoxFit.cover, // "Cover" estira la foto para llenar todo el fondo
          ),
        ),
        
        // CAPA 2 (Efecto): El difuminado y un velo oscuro
        Positioned.fill(
          child: BackdropFilter(
            // Ajusta estos números si lo quieres más o menos borroso (ej. 5.0 o 15.0)
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              // Usamos un velo NEGRO semitransparente para que la tarjeta blanca resalte más.
              // Si prefieres que se vea más claro, cambia Colors.black por Colors.white
              color: Colors.black.withOpacity(0.3), 
            ),
          ),
        ),

        // CAPA 3 (Frente): El contenido real (la tarjeta del formulario)
        SafeArea(
          child: Center(
            child: child
          ),
        ),
      ],
    );
  }
}