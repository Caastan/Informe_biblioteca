import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart'; // Asegúrate de importarlo

class CuentaScreen extends StatefulWidget {
  @override
  _CuentaScreenState createState() => _CuentaScreenState();
}

class _CuentaScreenState extends State<CuentaScreen> {
  void _devolverPrestamo(String prestamoId, String libroId) async {
    await FirebaseFirestore.instance.collection('prestamos').doc(prestamoId).update({
      'estado': 'Devuelto',
      'fechaDevolucion': Timestamp.now(),
    });
    await FirebaseFirestore.instance.collection('libros').doc(libroId).update({
      'estado': 'Disponible',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Devolución realizada')),
    );
  }

  void _generarYGuardarInforme() async {
    // Obtén los datos de préstamos desde Firestore
    QuerySnapshot prestamosSnapshot =
        await FirebaseFirestore.instance.collection('prestamos').get();

    // Crea el documento PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: prestamosSnapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return pw.Container(
                margin: pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  'Lector: ${data['lector']}\nLibro: ${data['libroTitulo']}\nEstado: ${data['estado']}\n',
                  style: pw.TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          );
        },
      ),
    );

    // Convierte el documento a bytes
    final bytes = await pdf.save();

    // Obtén el directorio de documentos del dispositivo
    final output = await getApplicationDocumentsDirectory();
    final filePath = '${output.path}/informe_prestamos.pdf';

    // Crea y guarda el archivo
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // Abre el PDF guardado en el dispositivo
    OpenFile.open(filePath);

    // Muestra un mensaje indicando la ubicación del archivo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF guardado y abierto en: $filePath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Cuenta - Préstamos'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generarYGuardarInforme,
            tooltip: 'Generar Informe de Préstamos',
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('prestamos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error al cargar préstamos'));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          final prestamos = snapshot.data!.docs;
          return ListView.builder(
            itemCount: prestamos.length,
            itemBuilder: (context, index) {
              final data = prestamos[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Lector: ${data['lector']}'),
                subtitle: Text('Libro: ${data['libroTitulo']}\nEstado: ${data['estado']}'),
                trailing: data['estado'] == 'Prestado'
                    ? TextButton(
                        onPressed: () {
                          _devolverPrestamo(prestamos[index].id, data['libroId']);
                        },
                        child: Text('Devolver'),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
