import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/database_helper.dart';
import '../models/note.dart';

class NoteService {
  final DatabaseHelper database = DatabaseHelper.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get notesCollection =>
      firestore.collection('notes');

  // Salvar nota no SQLite e Firestore
  Future<void> saveNote(Note note) async {
    if (note.cloudId != null) {
      await notesCollection.doc(note.cloudId).update(note.toFirestore());

      if (note.id != null) {
        await database.updateNote(note);
      }
    } else {
      final document = await notesCollection.add(note.toFirestore());

      await database.insertNote(
        Note(
          uid: note.uid,
          title: note.title,
          content: note.content,
          date: note.date,
          category: note.category,
          isArchived: note.isArchived,
          cloudId: document.id,
        ),
      );
    }
  }

  // Sincronizar notas locais e notas da nuvem
  Future<void> syncNotes(String uid) async {
    final localNotes = await database.getNotes(uid);

    for (final note in localNotes) {
      if (note.cloudId == null) {
        final document = await notesCollection.add(note.toFirestore());

        if (note.id != null) {
          await database.updateCloudId(note.id!, document.id);
        }
      }
    }

    final snapshot = await notesCollection.where('uid', isEqualTo: uid).get();

    for (final document in snapshot.docs) {
      final note = Note.fromFirestore(document.data(), document.id);

      await database.saveCloudNote(note);
    }
  }

  // Buscar notas locais
  Future<List<Note>> getNotes(String uid) async {
    return database.getNotes(uid);
  }

  // Arquivar ou desarquivar nota
  Future<void> setArchived(Note note, bool archived) async {
    final updatedNote = Note(
      id: note.id,
      cloudId: note.cloudId,
      uid: note.uid,
      title: note.title,
      content: note.content,
      date: note.date,
      category: note.category,
      isArchived: archived,
    );

    if (updatedNote.cloudId != null) {
      await notesCollection
          .doc(updatedNote.cloudId)
          .update(updatedNote.toFirestore());
    }

    if (updatedNote.id != null) {
      await database.updateNote(updatedNote);
    }
  }

  // Excluir nota do SQLite e Firestore
  Future<void> deleteNote(Note note) async {
    if (note.cloudId != null) {
      await notesCollection.doc(note.cloudId).delete();
    }

    if (note.id != null) {
      await database.deleteNote(note.id!);
    }
  }
}
