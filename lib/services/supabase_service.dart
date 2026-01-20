import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/constants/app_constants.dart';

class SupabaseService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // --- Advanced Features: Notifications (Updated) ---

  /// Fetch active notifications (with targeting)
  Future<void> fetchNotifications({String? userBranch}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      var query = _client.from('notifications').select();
      
      // If userBranch is provided, filter: target_branch IS NULL OR target_branch == userBranch
      // Note: Supabase 'or' syntax: `or=(target_branch.is.null,target_branch.eq.$userBranch)`
      if (userBranch != null) {
        query = query.or('target_branch.is.null,target_branch.eq.$userBranch');
      }

      final response = await query.order('created_at', ascending: false);
      
      _notifications = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new notification (Admin)
  Future<void> createNotification({
    required String title,
    required String message,
    String type = 'info',
    int priority = 0,
    String? targetBranch, // Null = All
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _client.from('notifications').insert({
        'title': title,
        'message': message,
        'type': type,
        'priority': priority,
        'is_active': true,
        'target_branch': targetBranch,
      });

      // Refresh list
      await fetchNotifications();
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete (or deactivate) a notification (Admin)
  Future<void> deleteNotification(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Soft delete by setting is_active to false, or hard delete
      await _client.from('notifications').delete().eq('id', id);

      // Refresh list
      await fetchNotifications();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Advanced Features: Polls ---

  /// Fetch the currently active poll (if any)
  Future<Map<String, dynamic>?> fetchActivePoll() async {
    try {
      final response = await _client
          .from('polls')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
          
      if (response == null) return null;

      // Fetch votes for this poll to calculate stats
      final pollId = response['id'];
      final votesResponse = await _client
          .from('poll_votes')
          .select('option_index')
          .eq('poll_id', pollId);
          
      final votes = List<Map<String, dynamic>>.from(votesResponse);
      
      // Calculate counts
      final List<dynamic> options = response['options'] ?? [];
      final Map<int, int> counts = {};
      for (var v in votes) {
        final idx = v['option_index'] as int;
        counts[idx] = (counts[idx] ?? 0) + 1;
      }

      return {
        ...response,
        'total_votes': votes.length,
        'vote_counts': counts,
      };
    } catch (e) {
      debugPrint('Error fetching active poll: $e');
      return null;
    }
  }

  /// Fetch user's vote for a specific poll
  Future<int?> fetchUserPollVote(String pollId, String enrollment) async {
    try {
      final response = await _client
          .from('poll_votes')
          .select('option_index')
          .eq('poll_id', pollId)
          .eq('enrollment', enrollment)
          .maybeSingle();
      
      return response?['option_index'] as int?;
    } catch (e) {
      return null;
    }
  }

  /// Vote on a poll
  Future<void> voteOnPoll(String pollId, String enrollment, int optionIndex) async {
    try {
      await _client.from('poll_votes').insert({
        'poll_id': pollId,
        'enrollment': enrollment,
        'option_index': optionIndex,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error voting: $e');
      rethrow;
    }
  }

  /// Create a new poll (Admin)
  Future<void> createPoll(String question, List<String> options) async {
    try {
      // Deactivate all previous polls first (optional logic, but good for "Quick Poll")
      await _client.from('polls').update({'is_active': false}).neq('id', '00000000-0000-0000-0000-000000000000'); // Hacky 'all' update requires a filter usually

      await _client.from('polls').insert({
        'question': question,
        'options': options,
        'is_active': true,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating poll: $e');
      rethrow;
    }
  }

  /// Delete a poll (Admin)
  Future<void> deletePoll(String pollId) async {
    try {
      // Cascade delete should handle votes if configured, but let's be safe
      await _client.from('polls').delete().eq('id', pollId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting poll: $e');
      rethrow;
    }
  }

  // --- Advanced Features: Maintenance Mode ---

  /// Check if maintenance mode is enabled
  Future<bool> isMaintenanceModeEnabled() async {
    try {
      final response = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'maintenance_mode')
          .maybeSingle();
      
      if (response == null) return false;
      final value = response['value'];
      return value['is_enabled'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle maintenance mode (Admin)
  Future<void> setMaintenanceMode(bool enabled) async {
    try {
      await _client.from('app_settings').upsert({
        'key': 'maintenance_mode',
        'value': {'is_enabled': enabled, 'message': 'App is under maintenance'},
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting maintenance mode: $e');
      rethrow;
    }
  }


  // --- Advanced Features: Dynamic App CMS ---

  /// Fetch dynamic app theme configuration
  Future<Map<String, dynamic>> getAppThemeConfig() async {
    try {
      final response = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'app_theme')
          .maybeSingle();

      if (response == null) {
        return {
          'banner_text': 'Welcome to GCET Tracker',
          'banner_visible': false,
          'theme_color': '0xFF3B82F6', // Default Blue
          'min_version': '1.0.0',
        };
      }
      return response['value'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching app theme: $e');
      return {};
    }
  }

  /// Update dynamic app theme (Admin)
  Future<void> updateAppThemeConfig(Map<String, dynamic> config) async {
    try {
      await _client.from('app_settings').upsert({
        'key': 'app_theme',
        'value': config,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating app theme: $e');
      rethrow;
    }
  }

  // --- Feedback Features ---

  /// Save or update user (tracking)
  Future<void> saveUser(Map<String, dynamic> studentData) async {
    try {
      final enrollment = studentData['enrollment'];
      if (enrollment == null || enrollment == 'admin') return;

      debugPrint('SupabaseService: Saving user tracking for $enrollment');

      await _client.from('users').upsert({
        'enrollment': enrollment,
        'name': studentData['name'],
        'branch': studentData['branch'],
        'semester': studentData['semester'],
        'app_version': AppConstants.appVersion,
        'last_login': DateTime.now().toIso8601String(),
      }, onConflict: 'enrollment');
      
    } catch (e) {
      debugPrint('Error saving user to Supabase: $e');
      // Don't rethrow, this is a background tracking task
    }
  }

  /// Fetch user statistics for Admin Dashboard
  Future<Map<String, dynamic>> fetchUserStats() async {
    try {
      // Get total count
      final countResponse = await _client
          .from('users')
          .count(CountOption.exact);
      
      final totalUsers = countResponse;

      // Get active users (logged in within last 24 hours)
      final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
      final activeResponse = await _client
          .from('users')
          .count(CountOption.exact)
          .gte('last_login', oneDayAgo);

      final activeUsers = activeResponse;

      // Get department distribution
      final response = await _client.from('users').select('branch');
      
      final departmentStats = <String, int>{};
      for (final user in response) {
        final branch = user['branch'] as String?;
        if (branch != null && branch.isNotEmpty) {
          departmentStats[branch] = (departmentStats[branch] ?? 0) + 1;
        }
      }

      return {
        'total': totalUsers,
        'active': activeUsers,
        'departments': departmentStats,
      };
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      return {
        'total': 0,
        'active': 0,
        'departments': {},
      };
    }
  }

  /// Lookup a student by enrollment number (Admin)
  Future<Map<String, dynamic>?> lookupStudent(String enrollment) async {
    try {
      final response = await _client
          .from('users')
          .select('name, branch, semester, app_version, last_login')
          .eq('enrollment', enrollment)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Error looking up student: $e');
      return null;
    }
  }

  // --- Feedback Features ---

  /// Check if user has already submitted feedback
  Future<bool> hasUserSubmittedFeedback(String enrollment) async {
    try {
      final response = await _client
          .from('app_feedback')
          .select('enrollment')
          .eq('enrollment', enrollment)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('Error checking feedback status: $e');
      return false;
    }
  }

  /// Submit feedback
  Future<void> submitFeedback({
    required String enrollment,
    required bool liked,
    String? message,
  }) async {
    try {
      await _client.from('app_feedback').upsert({
        'enrollment': enrollment,
        'liked': liked,
        'message': message,
      });
      notifyListeners(); // Refresh if needed
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      rethrow;
    }
  }

  /// Fetch all feedback (Admin)
  Future<List<Map<String, dynamic>>> fetchFeedbacks() async {
    try {
      final response = await _client
          .from('app_feedback')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching feedbacks: $e');
      return [];
    }
  }


  // --- Advanced Features: User Restriction ---

  /// Check if a user is restricted
  Future<bool> isUserRestricted(String enrollment) async {
    try {
      final response = await _client
          .from('restricted_users')
          .select('enrollment')
          .eq('enrollment', enrollment)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      // Logic: If table doesn't exist, nobody is restricted. 
      // This is a safe fallback for dev environments.
      debugPrint('Error checking restriction status: $e');
      return false;
    }
  }

  /// Restrict a user (Admin)
  Future<void> restrictUser(String enrollment) async {
    try {
      await _client.from('restricted_users').upsert({
        'enrollment': enrollment,
        'restricted_at': DateTime.now().toIso8601String(),
        'restricted_by': 'admin', // Hardcoded for now
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error restricting user: $e');
      rethrow;
    }
  }

  /// Unrestrict a user (Admin)
  Future<void> unrestrictUser(String enrollment) async {
    try {
      await _client.from('restricted_users').delete().eq('enrollment', enrollment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error unrestricting user: $e');
      rethrow;
    }
  }

  // --- Advanced Features: Role Management (Event Moderators) ---

  /// Check user role
  Future<String?> checkUserRole(String enrollment) async {
    try {
      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('enrollment', enrollment)
          .maybeSingle();

      if (response == null) return null;
      return response['role'] as String?;
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return null;
    }
  }

  /// Assign role to a user (Admin)
  Future<void> assignRole(String enrollment, String role) async {
    try {
      await _client.from('user_roles').upsert({
        'enrollment': enrollment,
        'role': role,
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error assigning role: $e');
      rethrow;
    }
  }

  /// Remove role from a user (Admin)
  Future<void> removeRole(String enrollment) async {
    try {
      await _client.from('user_roles').delete().eq('enrollment', enrollment);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing role: $e');
      rethrow;
    }
  }

  /// Fetch all moderators (Admin)
  Future<List<Map<String, dynamic>>> fetchModerators() async {
    try {
      // Fetch roles
      final rolesResponse = await _client
          .from('user_roles')
          .select()
          .order('created_at', ascending: false);
      
      final roles = List<Map<String, dynamic>>.from(rolesResponse);
      final results = <Map<String, dynamic>>[];

      // Enrich with names from 'users' table
      for (var roleEntry in roles) {
        final enrollment = roleEntry['enrollment'];
        final user = await lookupStudent(enrollment);
        
        results.add({
          'enrollment': enrollment,
          'role': roleEntry['role'],
          'name': user?['name'] ?? 'Unknown',
          'branch': user?['branch'] ?? 'N/A',
        });
      }
      return results;
    } catch (e) {
      debugPrint('Error fetching moderators: $e');
      return [];
    }
  }

  /// Fetch data for Activity Heatmap (Logins by Hour)
  Future<Map<int, int>> fetchActivityHeatmap() async {
    try {
      final since = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      
      final response = await _client
          .from('users')
          .select('last_login')
          .gte('last_login', since);
      
      final Map<int, int> hourCounts = {};
      for (int i = 0; i < 24; i++) hourCounts[i] = 0;

      for (var row in response) {
        final timestamp = row['last_login'] as String?;
        if (timestamp != null) {
          final dt = DateTime.parse(timestamp).toLocal();
          final hour = dt.hour;
          hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
        }
      }
      return hourCounts;
    } catch (e) {
      debugPrint('Error fetching heatmap: $e');
      return {};
    }
  }
}

