import 'dart:async';
import 'dart:io';

import 'package:interact/interact.dart';
import 'package:path/path.dart' as path;
import 'package:stat_git_workspaces/src/util/cli_printer.dart';

import 'multi_command.dart';

class GitCommand {
  GitCommand(
    this.subcommand, {
    required this.workingDirectory,
    this.runAlways = false,
    String? promptCommandName,
    String? repoName,
    this.mode = CommandMode.batch,
  })  : promptCommandName = promptCommandName ?? subcommand[0],
        repoName = repoName ?? path.basename(workingDirectory) {
    // Setup completers
    _handle.future.then(
      (value) => _stdout.complete(_collectStream(value.stdout)),
    );
    _handle.future.then(
      (value) => _stderr.complete(_collectStream(value.stderr)),
    );

    // Run command
    bool execute = runAlways || mode.execute;

    if (!runAlways && mode.confirm) {
      if (mode == CommandMode.printCommands) {
        print('$workingDirectory/git ${subcommand.join(" ")}');
      }

      try {
        execute = CliPrinter.I.confirm(Confirm(
          prompt: 'Run $promptCommandName on $repoName?',
          defaultValue: true, // this is optional
          waitForNewLine: true, // optional and will be false by default
        ));
      } catch (e) {
        // Interrupting interact prompt could mess up console
        reset();
        rethrow;
      }
    }

    if (execute) {
      _handle.complete(
        Process.start(
          'git',
          subcommand,
          workingDirectory: workingDirectory,
        ),
      );
    } else {
      _handle.complete(DryRunProcess());
    }
  }

  final List<String> subcommand;
  final String workingDirectory;
  final bool runAlways;
  final String promptCommandName;
  final String repoName;
  final CommandMode mode;

  late final _handle = Completer<Process>();

  Future<int> get exitCode => _handle.future.then((e) => e.exitCode);

  Future<bool> run() => exitCode.then((code) => code == 0);

  Future<String> adaptiveOutput() => run().then(
        (value) => value ? stdout : Future.error(stderr),
      );

  final _stdout = Completer<String>();

  Future<String> get stdout => _stdout.future;

  final _stderr = Completer<String>();

  Future<String> get stderr => _stderr.future;

  Future<List<String>> get results async {
    return stdout.then(_splitToLines);
  }

  static Future<String> _collectStream(Stream<List<int>> data) => data
      .transform(const SystemEncoding().decoder)
      .join()
      .then((value) => value.trim());

  static List<String> _splitToLines(String msg) => msg.trim().split('\n');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitCommand &&
          runtimeType == other.runtimeType &&
          subcommand == other.subcommand &&
          workingDirectory == other.workingDirectory;

  @override
  int get hashCode => subcommand.hashCode ^ workingDirectory.hashCode;
}

class DryRunProcess implements Process {
  final dummyText = SystemEncoding().encode('Dry-run');

  @override
  Future<int> get exitCode async => 0;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;

  @override
  int get pid => 0;

  @override
  Stream<List<int>> get stderr => Stream.value(dummyText);

  @override
  IOSink get stdin => throw UnimplementedError();

  @override
  Stream<List<int>> get stdout => Stream.value(dummyText);
}
