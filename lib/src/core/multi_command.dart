import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ansix/ansix.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:stat_git_workspaces/src/core/dir_stat.dart';
import 'package:stat_git_workspaces/src/util/cli_printer.dart';

import '../../cfg.dart';

abstract class TableHeaderEnum {
  String get desc;
}

abstract class MultiCommand<T extends TableHeaderEnum, R> extends Command<int> {
  MultiCommand({
    bool addBatchOption = true,
    bool addDryRunOption = true,
  }) {
    argParser.addOption(
      'workspace',
      abbr: 'w',
      aliases: ['ws', 'root', 'r'],
      defaultsTo: config.getWorkspaceDir().path,
      help: 'Workspace root containing Git projects',
      valueHelp: '~/ws/',
    );

    argParser.addFlag(
      'batch',
      abbr: 'b',
      defaultsTo: !addBatchOption,
      help: 'Automatically run commands',
      hide: addBatchOption,
    );

    argParser.addFlag(
      'dry-run',
      abbr: 'd',
      defaultsTo: false,
      help: 'Print print commands instead of running. Implies -b',
      hide: addDryRunOption,
    );

    _table = Map.fromEntries(enumCols.map(
      (header) => MapEntry(header.desc, <AnsiText>[]),
    ));
  }

  // Override Interface
  Future<R> processGitRepo(GitRepo repo, CommandMode mode);

  String get describeInitAction;

  List<T> get enumCols;

  FutureOr<AnsiText> formatGitRepo({
    required T header,
    required GitRepo gitRepo,
    R? results,
  });

  // Override interface with defaults

  /// Hook for processing on nonGit directory
  /// TODO: Use a result object
  Future<void> processNonGitDir(NonGitRepo dir, CommandMode mode) async {}

  Future<int> afterProcess(CommandMode mode) async {
    AnsiX.printStyled(build(), textStyle: const AnsiTextStyle());
    return 0;
  }

  AnsiText formatNonGit(T header, String repoName) {
    if (header.desc == _table.keys.first) {
      return AnsiText(repoName);
    }
    if (header.desc == _table.keys.skip(1).first) {
      return AnsiText(
        'No Git Repo',
        foregroundColor: AnsiColor.red,
      );
    }
    return blank;
  }

  // Values
  final config = Config.get();

  late final Map<String, List<AnsiText>> _table;

  final blank = AnsiText(
    '-',
    foregroundColor: AnsiColor.grey27,
    alignment: AnsiTextAlignment.center,
  );

  // Methods
  CommandMode determineCommandMode() {
    if (argResults?['dry-run']) return CommandMode.printCommands;
    bool? batchFlag = argResults?['batch'];
    return switch (batchFlag) {
      (true) => CommandMode.batch,
      (false) => CommandMode.confirmEach,
      (null) => CommandMode.noBatchOption,
    };
  }

  @override
  FutureOr<int>? run() async {
    final ws = Directory(argResults!['workspace']);
    final lsAll = await ws.list().toList();
    final projects = lsAll.whereType<Directory>().toList(growable: false);
    projects.sort((a, b) => a.path.compareTo(b.path));

    final mode = determineCommandMode();

    final dirs = projects.map((e) => basename(e.path)).toList(growable: false);
    final dirPad = dirs.map((e) => e.length).reduce(max) + 2;
    final numProjects = projects.length;

    await CliPrinter.header(describeInitAction);

    CliPrinter.I.setProgressBar(
      length: numProjects,
      size: 0.5,
      leftPrompt: (i) => i == projects.length
          ? '> Finishing'.padRight(dirPad)
          : '> ${dirs[i].padRight(dirPad)}: ',
      rightPrompt: (i) => '${i.toString().padLeft(3)} / $numProjects',
    );

    for (final project in projects) {
      await CliPrinter.I.increaseProgress();
      if (await DirStat.checkIfGitDir(project.path)) {
        final repo = GitRepo(
          root: project,
          args: argResults!,
          globalArgs: globalResults,
          mode: mode,
        );
        final result = await processGitRepo(repo, mode);
        for (final header in enumCols) {
          _addField(
            header,
            await formatGitRepo(
              header: header,
              gitRepo: repo,
              results: result,
            ),
          );
        }
      } else {
        final nonRepo = NonGitRepo(
          name: DirStat.getNameFromDir(project),
          args: argResults!,
          globalArgs: globalResults,
        );
        await processNonGitDir(nonRepo, mode);
        for (final header in enumCols) {
          _addField(header, formatNonGit(header, nonRepo.name));
        }
      }
    }

    await CliPrinter.I.finishProgress();

    return afterProcess(mode);
  }

  AnsiTable build() => AnsiTable.fromMap(
        _table,
        headerTextTheme: AnsiTextTheme(
          style: AnsiTextStyle(
            bold: true,
          ),
          foregroundColor: AnsiColor.cyan1,
        ),
        border: AnsiBorder(type: AnsiBorderType.header),
      );

  // Util

  void _addField(T header, AnsiText value) {
    _table[header.desc]!.add(value);
  }
}

enum CommandMode {
  batch(confirm: false),
  confirmEach(confirm: true),
  printCommands(execute: false, confirm: false),
  noBatchOption(execute: true, confirm: false),
  ;

  const CommandMode({this.execute = true, required this.confirm});

  final bool execute;
  final bool confirm;
}
