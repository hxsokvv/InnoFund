import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailPage extends StatelessWidget {
  final String projectId;

  const PostDetailPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Proyecto'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          Map<String, dynamic> projectData =
              snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> imageUrls = projectData['imageUrls'] ?? [];
          double goalAmount = projectData.containsKey('goalAmount') &&
                  projectData['goalAmount'] != null
              ? double.tryParse(projectData['goalAmount'].toString()) ?? 0.0
              : 0.0;
          double currentAmount = projectData.containsKey('currentAmount') &&
                  projectData['currentAmount'] != null
              ? double.tryParse(projectData['currentAmount'].toString()) ?? 0.0
              : 0.0;

          double progress = (goalAmount > 0)
              ? (currentAmount / goalAmount).clamp(0.0, 1.0)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Galería de imágenes
                if (imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[300],
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                const SizedBox(height: 16),

                // Información del proyecto
                Text(
                  projectData['description'] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),

                // Meta y monto recaudado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Meta:',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '\$${goalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recaudado:',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '\$${currentAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 16),

                // Sección adicional: botones o acciones
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Acción de donar o cualquier acción relacionada
                      },
                      child: const Text('Donar'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        // Acción secundaria
                      },
                      child: const Text('Compartir'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
