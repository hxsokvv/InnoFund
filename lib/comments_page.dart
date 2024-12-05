import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsPage extends StatelessWidget {
  final String projectId;

  const CommentsPage({Key? key, required this.projectId}) : super(key: key);

  String _timeAgo(Timestamp timestamp) {
    final DateTime postTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos';
    } else {
      return 'Justo ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('postId', isEqualTo: projectId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay comentarios aún.'),
                  );
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData =
                        comments[index].data() as Map<String, dynamic>;
                    final commentText = commentData['comment'];
                    final timestamp = commentData['timestamp'] as Timestamp;
                    final commenterId = commentData['userId'];
                    final commentId = comments[index].id;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(commenterId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        final String fullName =
                            '${userData['name'] ?? 'Usuario'} ${userData['lastName'] ?? ''}';
                        final String profilePicture =
                            userData['profilePicture'] ??
                                'https://via.placeholder.com/150';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(profilePicture),
                          ),
                          title: Text(
                            fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(commentText),
                              const SizedBox(height: 5),
                              Text(
                                _timeAgo(timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up_alt_outlined),
                                onPressed: () {
                                  _toggleLike(commentId, commenterId);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.reply_outlined),
                                onPressed: () {
                                  _replyToComment(context, commentId);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInputField(context),
        ],
      ),
    );
  }

  Widget _buildCommentInputField(BuildContext context) {
    final TextEditingController _commentController = TextEditingController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2), // Sombra superior
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario...',
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              if (_commentController.text.trim().isNotEmpty) {
                _addComment(context, _commentController.text.trim());
                _commentController.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(BuildContext context, String comment) async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('comments').add({
      'postId': projectId,
      'comment': comment,
      'timestamp': Timestamp.now(),
      'userId': userId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comentario añadido.')),
    );
  }

  Future<void> _toggleLike(String commentId, String commenterId) async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    DocumentReference commentRef =
        FirebaseFirestore.instance.collection('comments').doc(commentId);

    DocumentSnapshot commentSnapshot = await commentRef.get();
    if (commentSnapshot.exists) {
      final commentData = commentSnapshot.data() as Map<String, dynamic>;
      List<dynamic> likes = commentData['likes'] ?? [];

      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
      }

      await commentRef.update({'likes': likes});
    }
  }

  void _replyToComment(BuildContext context, String commentId) {
    TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Responder comentario'),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(
              hintText: 'Escribe tu respuesta...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (replyController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance.collection('replies').add({
                    'commentId': commentId,
                    'reply': replyController.text.trim(),
                    'timestamp': Timestamp.now(),
                    'userId': FirebaseAuth.instance.currentUser!.uid,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Respuesta añadida.')),
                  );
                }
              },
              child: const Text('Responder'),
            ),
          ],
        );
      },
    );
  }
}
