/// Model data yang merepresentasikan satu komentar dari JSONPlaceholder.
///
/// Semua field bersifat final (immutable) agar objek tidak bisa diubah
/// setelah dibuat — ini adalah best practice untuk model data.
class Comment {
  /// ID dari post yang memiliki komentar ini.
  final int postId;

  /// ID unik komentar.
  final int id;

  /// Nama pengirim komentar.
  final String name;

  /// Alamat email pengirim.
  final String email;

  /// Isi/body dari komentar.
  final String body;

  /// Constructor utama — semua field wajib diisi.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// Factory constructor untuk parsing JSON dari API.
  ///
  /// Menggunakan operator `as?` dan `?? defaultValue` agar aman dari:
  /// - Field yang hilang (null dari Map).
  /// - Field dengan tipe data yang salah (as? mengembalikan null).
  ///
  /// Contoh JSON yang diharapkan:
  /// ```json
  /// {
  ///   "postId": 1,
  ///   "id": 1,
  ///   "name": "John",
  ///   "email": "john@example.com",
  ///   "body": "Great post!"
  /// }
  /// ```
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // Pattern `is int ? value : 0` lebih aman dari `as int? ?? 0`.
      //
      // Mengapa? Karena `as int?` akan THROW TypeError jika value
      // bukan int dan bukan null (misal: String '999').
      // Sedangkan `is int` hanya mengembalikan true/false, tidak pernah throw.
      postId: json['postId'] is int ? json['postId'] as int : 0,
      id: json['id'] is int ? json['id'] as int : 0,

      // Sama untuk String: `is String` aman dari tipe data yang salah.
      name: json['name'] is String ? json['name'] as String : '',
      email: json['email'] is String ? json['email'] as String : '',
      body: json['body'] is String ? json['body'] as String : '',
    );
  }

  /// Mengonversi objek Comment kembali menjadi Map JSON.
  /// Berguna untuk caching, serialisasi, atau debugging.
  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'id': id,
      'name': name,
      'email': email,
      'body': body,
    };
  }

  /// Override toString agar mudah dilihat saat debugging/print.
  @override
  String toString() {
    return 'Comment(postId: $postId, id: $id, name: $name, email: $email)';
  }

  /// Override == dan hashCode agar dua objek Comment dengan nilai
  /// field yang sama dianggap equal (berguna untuk testing & perbandingan).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.postId == postId &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.body == body;
  }

  @override
  int get hashCode {
    return Object.hash(postId, id, name, email, body);
  }
}
