import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';

class PollCard extends StatefulWidget {
  const PollCard({super.key});

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  bool _isLoading = false;
  int? _userVoteIndex; // Index of option user voted for
  
  @override
  void initState() {
    super.initState();
    _checkUserVote();
  }

  Future<void> _checkUserVote() async {
    final supabase = context.read<SupabaseService>();
    final activePoll = await supabase.fetchActivePoll(); // Fetch latest
    final user = context.read<AuthService>().currentUser;

    if (activePoll != null && user != null && mounted) {
      final vote = await supabase.fetchUserPollVote(activePoll['id'], user.enrollment);
      if (mounted) {
        setState(() => _userVoteIndex = vote);
      }
    }
  }

  Future<void> _vote(String pollId, int index) async {
    setState(() => _isLoading = true);
    final user = context.read<AuthService>().currentUser;
    final supabase = context.read<SupabaseService>();

    if (user != null) {
      await supabase.voteOnPoll(pollId, user.enrollment, index);
      await _checkUserVote(); // Refresh vote status (and poll counts ideally)
      // Ideally, poll counts should be refreshed in parent or here
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: context.read<SupabaseService>().fetchActivePoll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink(); // No active poll
        }

        final poll = snapshot.data!;
        final options = List<dynamic>.from(poll['options'] ?? []);
        final counts = Map<String, int>.from(poll['vote_counts']?.map((k, v) => MapEntry(k.toString(), v)) ?? {});
        final totalVotes = poll['total_votes'] as int? ?? 0;
        final hasVoted = _userVoteIndex != null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Row(
                     children: [
                       Icon(Icons.poll, color: Color(0xFF8B5CF6), size: 20),
                       SizedBox(width: 8),
                       Text(
                         'Quick Poll',
                         style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
                       ),
                     ],
                   ),
                   if (hasVoted)
                     Text('$totalVotes votes', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                 ],
               ),
              const SizedBox(height: 12),
              Text(
                poll['question'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else ...options.asMap().entries.map((entry) {
                final index = entry.key;
                final text = entry.value.toString();
                final count = counts[index.toString()] ?? 0;
                final percentage = totalVotes == 0 ? 0.0 : (count / totalVotes);
                final isSelected = _userVoteIndex == index;

                if (hasVoted) {
                  // Show Progress Bars
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF8B5CF6) : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${(percentage * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                            FractionallySizedBox(
                              widthFactor: percentage == 0 ? 0.01 : percentage, // avoid 0 width visual glitch if needed, or check
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.white24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else {
                  // Show Vote Buttons
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton(
                      onPressed: () => _vote(poll['id'], index),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(text, style: const TextStyle(fontSize: 15)),
                    ),
                  );
                }
              }),
            ],
          ),
        );
      },
    );
  }
}
