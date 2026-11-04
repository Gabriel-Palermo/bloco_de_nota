import 'package:bloco_de_nota/models/note.dart';
import 'package:bloco_de_nota/pages/login_page.dart';
import 'package:bloco_de_nota/pages/note_form_page.dart';
import 'package:bloco_de_nota/services/auth_service.dart';
import 'package:bloco_de_nota/services/note_service.dart';
import 'package:bloco_de_nota/widgets/note_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteService noteService = NoteService();
  final AuthService authService = AuthService();
  final TextEditingController searchController = TextEditingController();

  List<Note> notes = [];
  bool isLoading = true;
  bool showArchived = false;
  String searchText = '';

  List<Note> get filteredNotes {
    final query = searchText.toLowerCase().trim();

    return notes.where((note) {
      final correctStatus = note.isArchived == showArchived;

      final matchesSearch =
          note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);

      return correctStatus && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final localNotes = await noteService.getNotes(user.uid);

      if (mounted) {
        setState(() {
          notes = localNotes;
          isLoading = false;
        });
      }

      await noteService.syncNotes(user.uid);

      final updatedNotes = await noteService.getNotes(user.uid);

      if (mounted) {
        setState(() {
          notes = updatedNotes;
        });
      }
    } catch (e) {
      debugPrint('ERRO AO CARREGAR/SINCRONIZAR NOTAS: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteNote(Note note) async {
    try {
      await noteService.deleteNote(note);
      await loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota deletada com sucesso!')),
        );
      }
    } catch (e) {
      debugPrint('ERRO AO DELETAR NOTA: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao deletar nota: $e')));
      }
    }
  }

  Future<void> archiveNote(Note note) async {
    try {
      await noteService.setArchived(note, !note.isArchived);
      await loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              note.isArchived ? 'Nota desarquivada!' : 'Nota arquivada!',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('ERRO AO ARQUIVAR NOTA: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao arquivar nota: $e')));
      }
    }
  }

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Future<void> openEditNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormPage(note: note)),
    );

    await loadNotes();
  }

  Future<void> openNewNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteFormPage()),
    );

    await loadNotes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayedNotes = filteredNotes;

    final activeCount = notes.where((note) => !note.isArchived).length;
    final archivedCount = notes.where((note) => note.isArchived).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas notas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: showArchived
          ? null
          : FloatingActionButton.extended(
              onPressed: openNewNote,
              backgroundColor: const Color(0xff6c4ab6),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nova Nota',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Color(0xFF77717f), fontSize: 13),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar notas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('Ativas ($activeCount)'),
                    selected: !showArchived,
                    onSelected: (_) {
                      setState(() {
                        showArchived = false;
                      });
                    },
                    selectedColor: const Color(0xffede5fa),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Arquivadas ($archivedCount)'),
                    selected: showArchived,
                    onSelected: (_) {
                      setState(() {
                        showArchived = true;
                      });
                    },
                    selectedColor: const Color(0xffede5fa),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (displayedNotes.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        searchText.isNotEmpty
                            ? Icons.search_off_rounded
                            : showArchived
                            ? Icons.archive_outlined
                            : Icons.sticky_note_2_rounded,
                        size: 55,
                        color: const Color(0xff6c4ab6),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        searchText.isNotEmpty
                            ? 'Nenhuma nota encontrada'
                            : showArchived
                            ? 'Nenhuma nota arquivada'
                            : 'Nenhuma nota ainda',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchText.isNotEmpty
                            ? 'Tente pesquisar outro termo.'
                            : showArchived
                            ? 'Suas notas arquivadas aparecerão aqui.'
                            : 'Crie sua primeira nota.',
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: displayedNotes.length,
                  itemBuilder: (context, index) {
                    final note = displayedNotes[index];

                    return NoteCard(
                      note: note,
                      onTap: () => openEditNote(note),
                      onDelete: () => deleteNote(note),
                      onArchive: () => archiveNote(note),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
