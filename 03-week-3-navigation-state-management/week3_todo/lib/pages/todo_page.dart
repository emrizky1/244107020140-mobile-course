import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodoListProvider);
    final filter = ref.watch(todoFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo Riverpod'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<TodoFilter>(
              segments: const [
                ButtonSegment(value: TodoFilter.all, label: Text('Semua')),
                ButtonSegment(value: TodoFilter.active, label: Text('Aktif')),
                ButtonSegment(value: TodoFilter.completed, label: Text('Selesai')),
              ],
              selected: {filter},
              onSelectionChanged: (selected) {
                ref.read(todoFilterProvider.notifier).setFilter(selected.first);
              },
            ),
          ),
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('Belum ada tugas'))
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return TodoTile(
                        key: ValueKey(todo.id),
                        todo: todo,
                        onToggle: (_) => ref
                            .read(todoListProvider.notifier)
                            .toggle(todo.id),
                        onDelete: () => ref
                            .read(todoListProvider.notifier)
                            .remove(todo.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                ref.read(todoListProvider.notifier).add(text);
              }
              controller.clear();
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}

class ProductsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 2));
    return ['Keyboard', 'Mouse', 'Monitor'];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<List<String>> _fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    return ['Keyboard', 'Mouse', 'Monitor', 'Headset'];
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<String>>(
  ProductsNotifier.new,
);

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $err'),
              FilledButton(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) => ListTile(title: Text(products[index])),
        ),
      ),
    );
  }
}