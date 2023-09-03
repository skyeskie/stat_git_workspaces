import 'dart:io';

import 'package:ansix/ansix.dart';
import 'package:interact/interact.dart';
// ignore: implementation_imports
import 'package:interact/src/framework/framework.dart';

class CliPrinter {
  static final CliPrinter _instance = CliPrinter._();

  static String _blank(int i) => '';

  CliPrinter._();

  factory CliPrinter() => _instance;

  static CliPrinter get I => CliPrinter();

  Context? _context;
  Progress? _progressBuilder;
  ProgressState? _activeProgress;
  int _progressCurrent = 0;
  bool _consoleLock = false;
  final List<String> _errorLines = [];

  void setProgressBar({
    required int length,
    double size = 1.0,
    String Function(int) leftPrompt = _blank,
    String Function(int) rightPrompt = _blank,
  }) {
    _activeProgress?.done();
    _activeProgress = null;
    _progressBuilder = Progress(
      length: length,
      size: size,
      leftPrompt: leftPrompt,
      rightPrompt: rightPrompt,
    );
    _context = Context();
    _setConsoleLock();
  }

  Future increaseProgress([int increment = 1]) async {
    if (!_consoleLock) throw StateError('No progress lock on console');
    // Pause to write errors then resume
    await _flushErrors();
    assert(_progressCurrent == _activeProgress!.current);
    _progressCurrent += increment;
    _activeProgress!.current = _progressCurrent;
  }

  void setCurrentProgress(int newValue) {
    if (!_consoleLock) throw StateError('No progress lock on console');
    _flushErrors();
    _activeProgress!.current = newValue;
    _progressCurrent = newValue;
    _activeProgress!.clear();
    _activeProgress!.increase(newValue);
  }

  Future _flushErrors({bool reLock = true}) async {
    _clearConsoleLock();
    await stdout.flush();
    _errorLines.forEach(print);
    if (_errorLines.isNotEmpty) print('\n');
    _errorLines.clear();
    await stdout.flush();
    if (reLock) _setConsoleLock();
    await stdout.flush();
  }

  Future finishProgress() async {
    if (!_consoleLock) throw StateError('Tried to clear nonexistent lock');
    await _flushErrors(reLock: false);
    _activeProgress = null;
    _progressBuilder = null;
    _progressCurrent = 0;
    _context?.showCursor();
  }

  Future printError(Object? message) async {
    final lines = message.toString().split('\n').map((e) => e.cliError());
    _errorLines.addAll(lines);
    lines.forEach(printLine);
  }

  static Future _pc(Object? message, AnsiColor color) =>
      _instance.printLine(message.toString().withForegroundColor(color));

  Future printLine(Object? message) async {
    if (_context == null) {
      await stdout.flush();
      stdout.writeln(message);
      await stdout.flush();
    } else {
      _context!.writeln(message.toString());
    }
  }

  Future _clearConsoleLock() async {
    if (!_consoleLock) throw StateError('Tried to clear nonexistent lock');
    _consoleLock = false;
    assert(_progressCurrent == _activeProgress!.current);
    _activeProgress!.done();
    _activeProgress = null;
  }

  void _setConsoleLock() {
    if (_consoleLock) throw StateError('Called lock on locked console');
    _consoleLock = true;
    _progressBuilder!.setContext(_context!);
    _activeProgress = _progressBuilder!.interact();
    _activeProgress!.current = _progressCurrent;
    _activeProgress!.increase(_progressCurrent);
  }

  // TODO: Figure out a way to still show progress
  // Probably along the lines of
  // - Start confirm
  // - Take confirm choice
  // - Delete confirm line
  // - Pause progress
  // - Re-print confirm line
  // - Resume progress
  bool confirm(Confirm dialog) {
    _clearConsoleLock();
    final choice = dialog.interact();
    _setConsoleLock();
    return choice;
  }

  static Future error(Object? message) => _instance.printError(message);

  static Future info(Object? message) => _pc(message, AnsiColor.lightSkyBlue1);

  static Future header(Object? message) => _pc(
        '\n$message'.bold(),
        AnsiColor.orange1,
      );

  static Future debug(Object? message) => _pc(message, AnsiColor.grey);
}

extension QuickColors on String {
  String cliError() => withForegroundColor(AnsiColor.red);
}
