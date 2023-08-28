import 'package:stat_git_workspaces/cfg.dart';
import 'package:stat_git_workspaces/src/cli_main.dart';

Future<int> statOnWorkdir(List<String> arguments) async {
  final cfg = Config.get();
  final cli = CliMain(
    cfg.commandName,
    'Display information for git project directories within a workspace',
  );

  return (await cli.run(arguments)) ?? 1;
}
