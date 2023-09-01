import 'package:ansix/ansix.dart';
import 'package:interact/interact.dart';

class CliPrinter {
  static final CliPrinter _instance = CliPrinter._();

  CliPrinter._();

  factory CliPrinter() => _instance;

  static CliPrinter get I => CliPrinter();

  Progress? _progressBuilder;
  ProgressState? _activeProgress;
  int? _progressCurrent;

  void setProgressBar(Progress p) {
    _activeProgress?.done();
    _progressBuilder = p;
    _activeProgress = p.interact();
  }

  void increaseProgress(int increment) {
    _activeProgress?.increase(increment);
    _progressCurrent = _activeProgress?.current;
  }

  void setCurrentProgress(int newValue) {
    _activeProgress?.current = newValue;
    _progressCurrent = _activeProgress?.current;
  }

  void finishProgress() {
    _activeProgress?.done();
    _activeProgress = null;
    _progressBuilder = null;
    _progressCurrent = null;
  }

  void printError(Object? message) => printLine(
        message.toString().withForegroundColor(AnsiColor.red),
      );

  void printInfo(Object? message) => printLine(
        message.toString().withForegroundColor(AnsiColor.lightSkyBlue1),
      );

  void printLine(Object? message) {
    _pauseConsoleLock();
    print(message);
    _resumeConsoleLock();
  }

  void _pauseConsoleLock() {
    _progressCurrent = _activeProgress?.current;
    _activeProgress?.done();
    _activeProgress = null;
  }

  void _resumeConsoleLock() {
    _activeProgress = _progressBuilder?.interact();
    if (_progressCurrent != null) {
      _activeProgress?.current = _progressCurrent!;
    }
  }

  bool confirm(Confirm dialog) {
    _pauseConsoleLock();
    final choice = dialog.interact();
    _resumeConsoleLock();
    return choice;
  }

  static void error(Object? message) => _instance.printError(message);

  static void info(Object? message) => _instance.printInfo(message);

  static void debug(Object? message) => _instance.printLine(
        message.toString().withForegroundColor(AnsiColor.grey),
      );
}
