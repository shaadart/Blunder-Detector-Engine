import 'package:chess/chess.dart';

void main() {
  var c = Chess();
  var result = c.move('e4');
  print('Move result type: ${result.runtimeType}');
  print('Move result: $result');
  
  var history = c.history;
  print('History type: ${history.runtimeType}');
  print('History: $history');
  
  // Test verbose history
  c.move('e5');
  var verboseHistory = c.getHistory({'verbose': true});
  print('\nVerbose history type: ${verboseHistory.runtimeType}');
  print('Verbose history: $verboseHistory');
  if (verboseHistory.isNotEmpty) {
    print('First move: ${verboseHistory[0]}');
    print('First move type: ${verboseHistory[0].runtimeType}');
  }
}
