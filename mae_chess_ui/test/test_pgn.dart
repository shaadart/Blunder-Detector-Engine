import 'package:chess/chess.dart';

void main() {
  var c = Chess();
  
  var pgn = '''[Event "Live Chess"]
[Site "Chess.com"]
[Date "2024.01.15"]
[White "Player1"]
[Black "Player2"]
[Result "1-0"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 1-0''';

  print('Testing PGN parsing...');
  var result = c.load_pgn(pgn);
  print('load_pgn result: $result');
  
  if (result) {
    var history = c.getHistory({'verbose': true});
    print('History length: ${history.length}');
  } else {
    print('PGN failed to parse!');
  }
}
