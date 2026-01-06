import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../models/note.dart';
import 'note_form_screen.dart';

/// Notes list screen - main screen after login
///
/// Displays all user's notes with:
/// - Search functionality (client-side)
/// - List of notes with preview
/// - FAB to add new note
/// - Logout option in AppBar
class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch notes when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).fetchNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    await authProvider.signOut();
    notesProvider.clear();
  }

  Future<void> _handleRefresh() async {
    await Provider.of<NotesProvider>(context, listen: false).fetchNotes();
  }

  Future<void> _handleDeleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);
      final success = await notesProvider.deleteNote(noteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Note deleted' : 'Failed to delete note'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToNoteForm({Note? note}) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => NoteFormScreen(note: note)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notesProvider = Provider.of<NotesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes by title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notesProvider.searchNotes('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                notesProvider.searchNotes(value);
              },
            ),
          ),

          // Error message banner
          if (notesProvider.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connection Error',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notesProvider.errorMessage!,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    color: Colors.red[700],
                    onPressed: _handleRefresh,
                    tooltip: 'Retry',
                  ),
                ],
              ),
            ),

          // Notes list
          Expanded(
            child: notesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notesProvider.notes.isEmpty
                ? _buildEmptyState(notesProvider)
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notesProvider.notes.length,
                      itemBuilder: (context, index) {
                        final note = notesProvider.notes[index];
                        return _buildNoteCard(note);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNoteForm(),
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(NotesProvider notesProvider) {
    final isSearching = notesProvider.searchQuery.isNotEmpty;
    final hasError = notesProvider.errorMessage != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError
                ? Icons.cloud_off_outlined
                : (isSearching ? Icons.search_off : Icons.note_outlined),
            size: 80,
            color: hasError ? Colors.orange[400] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasError
                ? 'Notes Not Loaded'
                : (isSearching ? 'No notes found' : 'No notes yet'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: hasError ? Colors.orange[700] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              hasError
                  ? 'Your notes couldn\'t be loaded. Please check your internet connection and pull down to refresh.'
                  : (isSearching
                        ? 'Try a different search term'
                        : 'Tap the + button to create your first note'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hasError ? Colors.orange[600] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToNoteForm(note: note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _handleDeleteNote(note.id),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(note.updatedAt)} at ${timeFormat.format(note.updatedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
