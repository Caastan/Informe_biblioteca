import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'catalogo.dart';
import 'prestamo.dart';
import 'devolucion.dart';
import 'cuenta.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Firebase inicializado correctamente");
  runApp(BibliotecaApp());
}

class BibliotecaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblioteca',
      theme: ThemeData(
        primaryColor: Color(0xFF4CCCEB),
        appBarTheme: AppBarTheme(
          color: Color(0xFF4CCCEB),
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoSlab',
            fontSize: 20,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF4CCCEB),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.black,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/catalogo': (context) => CatalogoScreen(),
        '/prestamo': (context) => PrestamoScreen(),
        '/devolucion': (context) => DevolucionScreen(),
        '/cuenta': (context) => CuentaScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Definimos qué pantalla mostrar según la pestaña seleccionada
  Widget _getBody() {
    if (_selectedIndex == 0)
      return HomeTab();
    else if (_selectedIndex == 1)
      return CatalogoScreen();
    else
      return CuentaScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biblioteca'),
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/biblioteca_portada.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(child: _getBody()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Mi Cuenta',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/prestamo');
            },
            child: Text('Realizar Préstamo'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/devolucion');
            },
            child: Text('Realizar Devolución'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              showSearch(context: context, delegate: BookSearchDelegate());
            },
            child: Text('Buscar en Catálogo'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/cuenta');
            },
            child: Text('Ver Mis Préstamos'),
          ),
        ],
      ),
    );
  }
}

class BookSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('libros').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        // Filtra los libros que contengan en el título lo escrito en la query
        final libros = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final titulo = data['titulo'] ?? '';
          return titulo.toLowerCase().contains(query.toLowerCase());
        }).toList();

        if (libros.isEmpty) {
          return Center(child: Text('No se encontraron libros.'));
        }

        return ListView.builder(
          itemCount: libros.length,
          itemBuilder: (context, index) {
            final data = libros[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['titulo'] ?? ''),
              subtitle: Text(data['autor'] ?? ''),
              onTap: () {
                // Aquí podrías navegar a una pantalla de detalles del libro si lo deseas
                close(context, null);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text('Ingrese el nombre del libro para buscar.'));
    }
    return buildResults(context);
  }
}
