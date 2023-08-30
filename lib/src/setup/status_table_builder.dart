import 'package:ansix/ansix.dart';
import 'package:stat_git_workspaces/src/core/table_builder.dart';

import '../core/dir_stat.dart';

enum StatusHeaders implements TableHeaderEnum {
  name('Repository'),
  status('Result'),
  ;

  const StatusHeaders(this.desc);

  @override
  final String desc;
}

class StatusResult {
  const StatusResult({this.description = '?', this.color = AnsiColor.cyan1});

  const StatusResult.success([this.description = '✔️'])
      : color = AnsiColor.green;

  const StatusResult.error([this.description = 'X']) : color = AnsiColor.red;

  final String description;
  final AnsiColor color;

  AnsiText asAnsiText() => AnsiText(
        description,
        foregroundColor: color,
        alignment: AnsiTextAlignment.center,
      );
}

class StatusTableBuilder extends TableBuilder<StatusHeaders, StatusResult> {
  @override
  AnsiText addGitRow({
    required StatusHeaders header,
    required GitRepo gitRepo,
    StatusResult? results,
  }) =>
      switch (header) {
        StatusHeaders.name => AnsiText(gitRepo.name),
        StatusHeaders.status => (results ?? StatusResult()).asAnsiText(),
      };

  @override
  List<StatusHeaders> get enumCols => StatusHeaders.values;
}
