/// Model data untuk sebuah komentar dari JSONPlaceholder API.
///
/// Endpoint: GET /comments?postId={id}
/// Contoh response:
/// ```json
/// {
///   "postId": 1,
///   "id": 1,
///   "name": "id labore ex et quam laborum",
///   "email": "Eliseo@gardner.biz",
///   "body": "laudantium enim quasi est ..."
/// }
/// ```
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// ID pos yang memiliki komentar ini.
  final int postId;

  /// ID unik komentar.
  final int id;

  /// Nama/judul komentar.
  final String name;

  /// Alamat email komentator.
  final String email;

  /// Isi teks komentar.
  final String body;

  /// Factory constructor yang **aman null**.
  ///
  /// Setiap field menggunakan cast nullable (`as num?`, `as String?`)
  /// lalu operator `??` untuk default value, sehingga tidak akan crash
  /// meskipun JSON tidak mengandung field tersebut atau nilainya null.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // `as num?` menangani int maupun double dari JSON,
      // `.toInt()` mengonversi ke int dengan aman.
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Serialisasi balik ke Map untuk keperluan cache atau debugging.
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };

  @override
  String toString() =>
      'Comment(postId: $postId, id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          runtimeType == other.runtimeType &&
          postId == other.postId &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          body == other.body;

  @override
  int get hashCode => Object.hash(postId, id, name, email, body);
}
