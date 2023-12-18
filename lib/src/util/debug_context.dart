import 'package:interact/interact.dart';
// ignore: implementation_imports
import 'package:interact/src/framework/framework.dart';

class DebugContext extends Context {
  @override
  void writeln([String? text]) {
    final pre = renderCount.toString().padLeft(3);
    super.writeln('$pre | $text');
  }

  @override
  void increaseLinesCount() {
    //TODO: Temp for break
    super.increaseLinesCount();
  }

  @override
  void resetLinesCount() {
    // TODO: implement resetLinesCount
    super.resetLinesCount();
  }
}

class DebugProgress extends Progress {
  DebugProgress({required super.length});
}
