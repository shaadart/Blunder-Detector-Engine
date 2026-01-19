import 'package:chess/chess.dart';

String preprocessPgn(String pgn) {
  // Remove clock annotations {[%clk ...]}
  String cleaned = pgn.replaceAll(RegExp(r'\{[^}]*\}'), '');
  
  // Remove eval annotations like [%eval ...]
  cleaned = cleaned.replaceAll(RegExp(r'\[%[^\]]*\]'), '');
  
  // Fix Chess.com's "1... e5" notation - the library expects "1. e4 e5" format
  // Replace "N..." with just the move (remove the redundant move number for black)
  cleaned = cleaned.replaceAll(RegExp(r'\d+\.\.\.\s*'), '');
  
  // Split into header and moves sections
  // Find the first move number pattern to separate headers from moves
  final moveStartMatch = RegExp(r'\n\s*1\.\s').firstMatch(cleaned);
  if (moveStartMatch != null) {
    final moveStart = moveStartMatch.start;
    var headers = cleaned.substring(0, moveStart);
    var moves = cleaned.substring(moveStart);
    
    // Replace newlines with spaces in moves section only
    moves = moves.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    cleaned = headers + '\n\n' + moves;
  }
  
  return cleaned.trim();
}

void main() {
  var c = Chess();
  
  var pgn = '''[Event "Live Chess"]
[Site "Chess.com"]
[Date "2026.01.18"]
[Round "-"]
[White "shaadpgn"]
[Black "Arthaus616"]
[Result "0-1"]

1. d4 {[%clk 0:03:01.6]} 1... e5 {[%clk 0:02:57.9]} 2. dxe5 {[%clk 0:03:00.9]}
2... Nc6 {[%clk 0:02:58.3]} 3. f4 {[%clk 0:02:57.7]} 3... d6 {[%clk 0:02:57]} 4.
Nf3 {[%clk 0:02:57.1]} 4... dxe5 {[%clk 0:02:56.9]} 5. Qxd8+ {[%clk 0:02:58.2]}
5... Nxd8 {[%clk 0:02:56.3]} 6. Nxe5 {[%clk 0:02:55.8]} 6... Bd6 {[%clk
0:02:56.4]} 7. Nd3 {[%clk 0:02:52.4]} 7... Nf6 {[%clk 0:02:56.6]} 8. Nc3 {[%clk
0:02:51.3]} 8... O-O {[%clk 0:02:57.1]} 9. e4 {[%clk 0:02:52]} 9... Nd7 {[%clk
0:02:51.4]} 10. e5 {[%clk 0:02:41.2]} 10... Bc5 {[%clk 0:02:51]} 11. Nd5 {[%clk
0:02:41.5]} 11... c6 {[%clk 0:02:48.6]} 12. Nc3 {[%clk 0:02:28.6]} 12... Ne6
{[%clk 0:02:44.5]} 13. b4 {[%clk 0:02:24.9]} 13... Bd4 {[%clk 0:02:42.9]} 14.
Bb2 {[%clk 0:02:20.8]} 14... a5 {[%clk 0:02:36.6]} 15. g3 {[%clk 0:02:01.5]}
15... axb4 {[%clk 0:02:24.4]} 16. Nxb4 {[%clk 0:02:03.4]} 16... Nec5 {[%clk
0:02:12.9]} 17. O-O-O {[%clk 0:01:55.8]} 17... Bxc3 {[%clk 0:02:07.9]} 18. Bxc3
{[%clk 0:01:54.7]} 18... Na4 {[%clk 0:02:04.9]} 19. Bd2 {[%clk 0:01:32]} 19...
c5 {[%clk 0:02:04.9]} 20. Nd5 {[%clk 0:01:30.7]} 20... Nab6 {[%clk 0:01:59.8]}
21. Ne7+ {[%clk 0:01:24.9]} 21... Kh8 {[%clk 0:01:56.7]} 22. Kb1 {[%clk
0:01:13.7]} 22... Nc4 {[%clk 0:01:56.7]} 23. Bxc4 {[%clk 0:01:01.8]} 23... Nb6
{[%clk 0:01:54.7]} 24. Be2 {[%clk 0:00:51.1]} 24... Re8 {[%clk 0:01:54.8]} 25.
Nf5 {[%clk 0:00:48.1]} 25... Bxf5 {[%clk 0:01:54.4]} 26. g4 {[%clk 0:00:47.5]}
26... Be6 {[%clk 0:01:54.2]} 27. Bc3 {[%clk 0:00:27.1]} 27... Bxa2+ {[%clk
0:01:51.5]} 28. Kc1 {[%clk 0:00:27.9]} 28... Bc4 {[%clk 0:01:49.8]} 29. Bf3
{[%clk 0:00:21]} 29... Na4 {[%clk 0:01:36.3]} 30. Bd2 {[%clk 0:00:17.9]} 30...
Be6 {[%clk 0:01:28.4]} 31. Bxb7 {[%clk 0:00:16.2]} 31... Ra7 {[%clk 0:01:22.7]}
32. Bc6 {[%clk 0:00:16.5]} 32... Rb8 {[%clk 0:01:16.5]} 33. f5 {[%clk
0:00:13.8]} 33... Ba2 {[%clk 0:01:11.2]} 34. Bxa4 {[%clk 0:00:11.6]} 34... Rb1#
{[%clk 0:01:09.7]} 0-1''';

  print('Testing with preprocessPgn...');
  var cleanedPgn = preprocessPgn(pgn);
  print('Cleaned PGN:');
  print(cleanedPgn);
  print('\n---\n');
  
  var result = c.load_pgn(cleanedPgn);
  print('load_pgn result: $result');
  
  if (result) {
    var history = c.getHistory({'verbose': true});
    print('History length: ${history.length}');
    print('First few moves: ${history.take(5).map((m) => m['san'])}');
  } else {
    print('Still failing!');
  }
}
