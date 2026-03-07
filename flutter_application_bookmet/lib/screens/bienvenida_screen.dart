import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({Key? key}) : super(key: key);

  // Definimos los colores del diseño
  final Color kPrimaryOrange = const Color(0xFFFF8200); 
  final Color kDarkBlue = const Color(0xFF003087);      

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final User? user = FirebaseAuth.instance.currentUser; // Verificamos sesión

    return Scaffold(
      backgroundColor: Colors.white, 
      // Se eliminó el Drawer (menú desplegable) de aquí
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:[
            // 1. Barra de Navegación Superior
            _buildNavBar(context, user),

            const SizedBox(height: 60),

            // 2. Contenido Principal (Texto Central)
            _buildMainContent(size),

            const SizedBox(height: 40),

            // 3. Ilustración
            _buildFooterIllustration(size),

            // 4. Misión y Visión (Acerca de)
            Transform.translate( 
              offset: const Offset(0, -1),
              child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, 
                      end: Alignment.bottomCenter, 
                      colors: [const Color(0xFFFFA522), kPrimaryOrange], 
                      stops: const [0.0, 0.2]
                    )
                  ),
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.1, vertical: 60),
                  child: size.width > 800 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children:[
                            Expanded(flex: 4, child: _buildCircularImage()),
                            const SizedBox(width: 60),
                            Expanded(flex: 6, child: _buildTextContent()),
                          ],
                        )
                      : Column( 
                          children:[
                            _buildCircularImage(),
                            const SizedBox(height: 40),
                            _buildTextContent(),
                          ],
                        ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Barra de Navegación ---
  Widget _buildNavBar(BuildContext context, User? user) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Header.png'),
          fit: BoxFit.cover,
        )
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        children:[
          // Se eliminó el IconButton (hamburguesa) de la esquina superior izquierda
          Icon(Icons.local_library_rounded, color: kPrimaryOrange, size: 40),
          const SizedBox(width: 10),
          Text('BOOKMET', style: TextStyle(color: kPrimaryOrange, fontSize: 22, fontWeight: FontWeight.bold)),
          
          const Spacer(), // Empuja los botones hacia la derecha
          // Se eliminó el botón "Inicio" de aquí

          // Botones si NO hay sesión
          if (user == null) ...[
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkBlue, // Mismo color (Azul oscuro)
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/registro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkBlue, // Cambiado al mismo color que Iniciar Sesión
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              child: const Text('Registrarse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ] 
          // Botones si SÍ hay sesión
          else ...[
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/usuario'),
              icon: const Icon(Icons.dashboard, color: Colors.white),
              label: const Text('Ir al Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkBlue, // Unificado al azul oscuro
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)
              )
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMainContent(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
      child: Column(
        children:[
          Text(
            '¡Tu Centro de Conocimiento te Espera!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kPrimaryOrange,
              fontSize: size.width > 600 ? 42 : 32, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            constraints: const BoxConstraints(maxWidth: 800), 
            child: Text(
              'Bienvenido al corazón académico de la UNIMET. Únete a nuestra comunidad de aprendizaje y sumérgete en un entorno en constante evolución, donde cada libro y recurso digital es una oportunidad para innovar e inspirar tu futuro profesional.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 18, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterIllustration(Size size) {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/Book - transition.png',
        width: size.width,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
      )
    );
  }

  // --- Acerca De ---
  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text('¡Bienvenido a BOOKMET!', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text('Accede a una de las colecciones más completas del país. Disfruta de espacios de estudio colaborativo...', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        const SizedBox(height: 30),
        const Text('Nuestra Misión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Buscamos que el acceso a materiales de estudio en la UNIMET deje de ser un obstáculo...', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        const SizedBox(height: 20),
        const Text('Nuestra Visión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Queremos ser el ecosistema digital de referencia...', style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            _buildStat('3k+', 'Recursos\nAcadémicos'),
            _buildStat('5K+', 'Miembros\nComunidad'),
            _buildStat('200+', 'Bases de Datos\ny Revistas'),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularImage() {
    return Container(
      height: 400,
      width: 400,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow:[BoxShadow(color: Colors.black26, blurRadius: 10)],
        image: DecorationImage(image: AssetImage('assets/images/Acerca_de.png'))
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(number, style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}