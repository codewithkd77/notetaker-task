import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/supabase_service.dart';

/// Notes provider for CRUD operations
///
/// Handles all note operations with Supabase:
/// - Fetch all notes for current user
/// - Create new note
/// - Update existing note
/// - Delete note
/// - Client-side search/filter by title
///
/// Security: All operations automatically filtered by RLS policies
class NotesProvider with ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Note> get notes => _filteredNotes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  /// Fetch all notes for the current user
  /// RLS policies ensure only user's own notes are returned
  Future<void> fetchNotes() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await SupabaseService.from(
        'notes',
      ).select().order('created_at', ascending: false);

      _notes = (response as List).map((json) => Note.fromJson(json)).toList();

      _applySearch();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;

      // Check for network-related errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('network') ||
          errorString.contains('host lookup') ||
          errorString.contains('no address associated with hostname')) {
        _errorMessage =
            'No internet connection. Please check your network and try again.';
      } else {
        _errorMessage = 'Failed to load notes. ${e.toString()}';
      }

      notifyListeners();
    }
  }

  /// Create a new note
  Future<bool> createNote(String title, String content, String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final now = DateTime.now();
      final noteData = {
        'title': title,
        'content': content,
        'user_id': userId,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await SupabaseService.from('notes').insert(noteData);

      // Refresh notes list
      await fetchNotes();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;

      // Check for network-related errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('network') ||
          errorString.contains('host lookup') ||
          errorString.contains('no address associated with hostname')) {
        _errorMessage = 'No internet connection. Cannot create note.';
      } else {
        _errorMessage = 'Failed to create note. ${e.toString()}';
      }

      notifyListeners();
      return false;
    }
  }

  /// Update an existing note
  Future<bool> updateNote(String noteId, String title, String content) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final noteData = {
        'title': title,
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.from('notes').update(noteData).eq('id', noteId);

      // Refresh notes list
      await fetchNotes();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;

      // Check for network-related errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('network') ||
          errorString.contains('host lookup') ||
          errorString.contains('no address associated with hostname')) {
        _errorMessage = 'No internet connection. Cannot update note.';
      } else {
        _errorMessage = 'Failed to update note. ${e.toString()}';
      }

      notifyListeners();
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await SupabaseService.from('notes').delete().eq('id', noteId);

      // Refresh notes list
      await fetchNotes();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;

      // Check for network-related errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('socketexception') ||
          errorString.contains('network') ||
          errorString.contains('host lookup') ||
          errorString.contains('no address associated with hostname')) {
        _errorMessage = 'No internet connection. Cannot delete note.';
      } else {
        _errorMessage = 'Failed to delete note. ${e.toString()}';
      }

      notifyListeners();
      return false;
    }
  }

  /// Search/filter notes by title (client-side)
  void searchNotes(String query) {
    _searchQuery = query;
    _applySearch();
    notifyListeners();
  }

  /// Apply search filter to notes list
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = List.from(_notes);
    } else {
      _filteredNotes = _notes
          .where(
            (note) =>
                note.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all notes (used when signing out)
  void clear() {
    _notes = [];
    _filteredNotes = [];
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }
}
