import 'dart:io';

import 'package:args/args.dart';
import 'package:interact/interact.dart';
import 'package:path/path.dart' as path;
import 'package:repository_url/repository_url.dart';

import 'git_remote.dart';
import 'multi_command.dart';

part 'git_repo.dart';

sealed class DirStat {
  DirStat({
    required this.name,
    required ArgResults? args,
    required ArgResults? globalArgs,
  })  : _args = args,
        _globalArgs = globalArgs;

  DirStat.fromDirectory(
    Directory dir, {
    required ArgResults? args,
    required ArgResults? globalArgs,
  })  : name = getNameFromDir(dir),
        _args = args,
        _globalArgs = globalArgs;

  getArg(String key) {
    final argKeys = _args?.options ?? [];
    return argKeys.contains(key) ? (_args?[key]) : (_globalArgs?[key]);
  }

  final String name;

  final ArgResults? _args;

  final ArgResults? _globalArgs;

  static String getNameFromDir(Directory dir) => path.basename(dir.path);

  static Future<List<String>> runGitCmd(
    List<String> command, {
    required String workingDirectory,
  }) async {
    final cmd = await Process.start(
      'git',
      command,
      workingDirectory: workingDirectory,
    );

    final exitCode = await cmd.exitCode;

    if (exitCode != 0) {
      final error = await cmd.stderr
          .transform(
            const SystemEncoding().decoder,
          )
          .join();
      return Future.error(error);
    }

    final result = await cmd.stdout
        .transform(
          const SystemEncoding().decoder,
        )
        .join();
    return result.trim().split('\n');
  }

  static Future<bool> checkIfGitDir(String workingDirectory) async {
    return runGitCmd(
      ['rev-parse', '--show-toplevel'],
      workingDirectory: workingDirectory,
    ).then(
      (topLevel) => path.equals(
        topLevel.single.trim(),
        workingDirectory,
      ),
      onError: (error) => error.toString().contains('not a git repository')
          ? false
          : Future.error(error),
    );
  }
}

class NonGitRepo extends DirStat {
  NonGitRepo({
    required super.name,
    required super.args,
    required super.globalArgs,
  });
}
