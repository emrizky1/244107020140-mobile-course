import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  Todo(this.title, {this.done = false, String? id})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String title;
  final bool done;

  Todo copyWith({String? title, bool? done}) =>
      Todo(title ?? this.title, done: done ?? this.done, id: id);
}

class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => const [];

  void add(String title) => state = [...state, Todo(title)];

  void toggle(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id) todo.copyWith(done: !todo.done) else todo,
    ];
  }

  void remove(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

enum TodoFilter { all, active, completed }

class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.all;

  void setFilter(TodoFilter filter) => state = filter;
}

final todoFilterProvider =
    NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

final filteredTodoListProvider = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoFilterProvider);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoFilter.active:
      return todos.where((todo) => !todo.done).toList();
    case TodoFilter.completed:
      return todos.where((todo) => todo.done).toList();
    case TodoFilter.all:
      return todos;
  }
});