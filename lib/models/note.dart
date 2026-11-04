class Note {
  final int? id;
  final String? cloudId;

  final String uid;
  final String title;
  final String content;
  final String date;
  final String category;
  final bool isArchived;

  Note({
    this.id,
    this.cloudId,
    required this.uid,
    required this.title,
    required this.content,
    required this.date,
    this.category = 'Pessoal',
    this.isArchived = false,
  });

  // Dados utilizados pelo SQLite
  Map<String, dynamic> toMap() => {
    'id': id,
    'cloudId': cloudId,
    'uid': uid,
    'title': title,
    'content': content,
    'date': date,
    'category': category,
    'isArchived': isArchived ? 1 : 0,
  };

  // Dados utilizados pelo Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'title': title,
      'content': content,
      'date': date,
      'category': category,
      'isArchived': isArchived,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      cloudId: map['cloudId'] as String?,
      uid: map['uid'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: map['date'] as String,
      category: map['category'] as String? ?? 'Pessoal',
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
    );
  }

  factory Note.fromFirestore(Map<String, dynamic> map, String documentId) {
    return Note(
      cloudId: documentId,
      uid: map['uid'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      date: map['date'] as String,
      category: map['category'] as String? ?? 'Pessoal',
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }
}
