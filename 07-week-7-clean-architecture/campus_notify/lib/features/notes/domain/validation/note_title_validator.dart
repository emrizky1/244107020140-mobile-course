import '../../../../core/failures.dart';

Failure? validateNoteTitle(String title) {
  if (title.trim().isEmpty) {
    return const ValidationFailure('Title cannot be empty.');
  }
  return null;
}
