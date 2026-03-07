import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // Definimos los colores del diseño para usarlos fácilmente
  final Color kPrimaryOrange = const Color(0xFFFF8200); // Naranja similar al diseño
  final Color kDarkBlue = const Color(0xFF003087);      // Azul oscuro del botón
  final Color kMedBlue = const Color(0xFF1859A9);

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para hacer el diseño responsivo si es necesario
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco limpio
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        // Permite scroll si la pantalla es muy pequeña verticalmente
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Barra de Navegación Superior (NavBar)
            _buildNavBar(context),

            const SizedBox(height: 60), // Espacio vertical

            // 2. Contenido Principal (Texto Central)
            _buildMainContent(size),

            const SizedBox(height: 40), // Espacio antes de la ilustración

            // 3. Ilustración y Footer Inferior
            _buildFooterIllustration(size),

            //4. Misión y Visión traidos de "Acerca de"
            Transform.translate( //para evitar espacio en blanco entre las secciones
              offset: const Offset(0, -1),
              child: Container(
                  width: double.infinity,
                  //transición de colores:
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFA522), kPrimaryOrange], stops: const [0.0, 0.2])),

                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.1, 
                    vertical: 60
                  ),
                  child: size.width > 800 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 4, child: _buildCircularImage()),
                            const SizedBox(width: 60),
                            Expanded(flex: 6, child: _buildTextContent()),
                          ],
                        )
                      : Column( // Si la pantalla es pequeña, apilamos los elementos
                          children: [
                            _buildCircularImage(),
                            const SizedBox(height: 40),
                            _buildTextContent(),
                          ],
                        ),
                ),
            ),
            const SizedBox(height: 50)

          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    //Obteniendo el usuario de firebase para verificar inicio de sesión
    final User? user = FirebaseAuth.instance.currentUser;


    return Container(
      //para imagen de decoracion:
      //width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Header.png'),
          fit: BoxFit.cover,
        )
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        children: [
          Builder(
            builder: (WrappedContext) => IconButton( //Boton de menu desplegable
              onPressed: () => Scaffold.of(WrappedContext).openDrawer(), 
              icon: const Icon(Icons.menu, color: Color(0xFFFF8200), size: 30)
            ),
          ),
          Icon(Icons.local_library_rounded, color: kPrimaryOrange, size: 40),
          const SizedBox(width: 10),
          Text('BOOKMET', style: TextStyle(color: kPrimaryOrange, fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(), 

          if (MediaQuery.of(context).size.width > 800) ...[
             _buildNavLink(context, 'Inicio', '/'),
            const SizedBox(width: 30),
          ],

          //Estructura condicional:
          if (user == null) ...[
          ElevatedButton(
            // ¡Navegación al Login!
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
            child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 50),

          ElevatedButton(
            // Navegación al registro
            onPressed: () => Navigator.pushNamed(context, '/registro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kMedBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            ),
            child: const Text('Registrarse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
          ]
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/perfil');
              },
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text('Ver perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1859A9),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)
              )
            )
        ],
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String title, String route) {
    bool isActive = ModalRoute.of(context)?.settings.name == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: TextButton(
        // ¡Navegación a las otras pantallas!
        onPressed: () => Navigator.pushReplacementNamed(context, route),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? kPrimaryOrange : Colors.grey[700],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // --- Widget del Contenido Central de Texto ---
  Widget _buildMainContent(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1), // Margen horizontal dinámico
      child: Column(
        children: [
          Text(
            '¡Tu Centro de Conocimiento te Espera!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kPrimaryOrange,
              fontSize: size.width > 600 ? 42 : 32, // Fuente más pequeña en móviles
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            constraints: const BoxConstraints(maxWidth: 800), // Limita el ancho del párrafo
            child: Text(
              'Bienvenido al corazón académico de la UNIMET. Únete a nuestra comunidad de aprendizaje y sumérgete en un entorno en constante evolución, donde cada libro y recurso digital es una oportunidad para innovar e inspirar tu futuro profesional.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                height: 1.5, // Altura de línea para mejor lectura
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget de la Ilustración y Footer ---
  Widget _buildFooterIllustration(Size size) {
    return Container(
      width: double.infinity,
      child: Image.asset('assets/images/Book - transition.png',
      width: size.width,
      fit: BoxFit.fitWidth,
      gaplessPlayback: true,
      )
    );
  }



//----Widget de Acerca De------
// --- El contenido de texto (Misión, Visión y Estadísticas) ---
  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¡Bienvenido a BOOKMET!',
          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text(
          'Accede a una de las colecciones más completas del país. Disfruta de espacios de estudio colaborativo, consulta bases de datos de clase mundial y encuentra el soporte académico necesario para llevar tu carrera al siguiente nivel. ¡Explora, investiga e innova con nosotros!',
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 30),
        
        // Misión
        const Text('Nuestra Misión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Buscamos que el acceso a materiales de estudio en la UNIMET deje de ser un obstáculo. Nuestra misión es conectar a la comunidad universitaria a través de una plataforma donde el intercambio y la venta de materiales de estudio sean procesos ágiles, seguros y totalmente trazables.',
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 20),

        // Visión
        const Text('Nuestra Visión', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Queremos ser el ecosistema digital de referencia para el material académico en la universidad. Nos vemos como una herramienta centralizada que simplifique la vida del estudiante y el docente, haciendo que gestionar recursos sea algo orgánico y eficiente.',
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 40),

        // Estadísticas de la imagen
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStat('3k+', 'Recursos\nAcadémicos'),
            _buildStat('5K+', 'Miembros\nComunidad'),
            _buildStat('200+', 'Bases de Datos\ny Revistas'),
          ],
        ),
      ],
    );
  }

  // --- El placeholder del círculo con los libros ---
  Widget _buildCircularImage() {
    return Container(
      height: 400,
      width: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        //border: Border.all(color: Colors.white, width: 8), // Borde blanco grueso
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        image: const DecorationImage(image: AssetImage('assets/images/Acerca_de.png'))
      ),
    );
  }

//para las estadísticas:
  Widget _buildStat(String number, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
//-----------------------------

//Metodo para construir el Drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: kPrimaryOrange),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const[
              Icon(Icons.local_library_rounded, color: Colors.white, size: 50),
              SizedBox(height: 10),
              Text('Bookmet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
            ],
          )
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Inicio'),
          onTap: () => Navigator.pushReplacementNamed(context, '/')
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Acerca de'),
          onTap: () => Navigator.pushReplacementNamed(context, '/acerca_de')
        ),
        ListTile(
          leading: const Icon(Icons.auto_stories),
          title: const Text('Catálogo'),
          onTap: () => Navigator.pushReplacementNamed(context, '/registro')
        ),
      ],)
    );
  }
}