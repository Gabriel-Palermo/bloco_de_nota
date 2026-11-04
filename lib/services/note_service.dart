import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/database_helper.dart';
import '../models/note.dart';
import 'dart:async';

class NoteService {
  final DatabaseHelper database = DatabaseHelper.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get notesCollection =>
      firestore.collection('notes');

  // Salvar primeiro no SQLite
  Future<void> saveNote(Note note) async {
    int localId;

    if (note.id == null) {
      localId = await database.insertNote(
        Note(
          uid: note.uid,
          title: note.title,
          content: note.content,
          date: note.date,
          category: note.category,
          isArchived: note.isArchived,
          cloudId: note.cloudId,
          pendingSync: true,
        ),
      );
    } else {
      localId = note.id!;

      await database.updateNote(
        Note(
          id: localId,
          cloudId: note.cloudId,
          uid: note.uid,
          title: note.title,
          content: note.content,
          date: note.date,
          category: note.category,
          isArchived: note.isArchived,
          pendingSync: true,
        ),
      );
    }

    final savedNote = (await database.getNotes(
      note.uid,
    )).firstWhere((item) => item.id == localId);

    // Sincroniza em segundo plano, sem bloquear a tela.
    unawaited(_syncOneNote(savedNote).catchError((_) {}));
  }

  Future<void> _syncOneNote(Note note) async {
    if (note.id == null) return;

    String? cloudId = note.cloudId;

    if (cloudId == null) {
      final document = notesCollection.doc();

      cloudId = document.id;

      // Guarda o ID antes de tentar enviar ao Firebase.
      await database.updateCloudId(note.id!, cloudId);
    }

    await notesCollection.doc(cloudId).set(note.toFirestore());

    await database.markNoteSynced(note.id!, cloudId);
  }

  // Sincronizar notas locais e notas da nuvem
  Future<void> syncNotes(String uid) async {
    // Primeiro processa exclusões pendentes.
    final deletions = await database.getPendingDeletions(uid);

    for (final deletion in deletions) {
      try {
        await notesCollection.doc(deletion['cloudId'] as String).delete();
        await database.removePendingDeletion(deletion['id'] as int);
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          await database.removePendingDeletion(deletion['id'] as int);
        } else {
          rethrow;
        }
      }
    }

    // Envia alterações locais pendentes.
    final pendingNotes = await database.getPendingNotes(uid);

    for (final note in pendingNotes) {
      await _syncOneNote(note);
    }

    // Recupera notas da nuvem.
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

  // Arquivar ou desarquivar
  Future<void> setArchived(Note note, bool archived) async {
    await database.updateNote(
      Note(
        id: note.id,
        cloudId: note.cloudId,
        uid: note.uid,
        title: note.title,
        content: note.content,
        date: note.date,
        category: note.category,
        isArchived: archived,
        pendingSync: true,
      ),
    );

    try {
      final updatedNote = (await database.getNotes(
        note.uid,
      )).firstWhere((item) => item.id == note.id);

      await _syncOneNote(updatedNote);
    } catch (e) {
      // Mantém a alteração pendente para sincronizar depois.
    }
  }

  // Excluir nota
  Future<void> deleteNote(Note note) async {
    if (note.cloudId != null) {
      await database.addPendingDeletion(note.uid, note.cloudId!);
    }

    if (note.id != null) {
      await database.deleteNote(note.id!);
    }

    // Tenta excluir da nuvem; se falhar, fica na fila.
    try {
      if (note.cloudId != null) {
        await notesCollection.doc(note.cloudId).delete();
        final deletions = await database.getPendingDeletions(note.uid);

        for (final deletion in deletions) {
          if (deletion['cloudId'] == note.cloudId) {
            await database.removePendingDeletion(deletion['id'] as int);
          }
        }
      }
    } catch (e) {
      // Exclusão pendente será processada na próxima sincronização.
    }
  }
}
