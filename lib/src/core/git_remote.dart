import 'package:repository_url/repository_url.dart';

class GitRemote {
  final String name;
  final String branch;
  final RepositoryUrl uri;
  final int ahead;
  final int behind;
  final String? error;

  GitRemote({
    required this.name,
    required this.branch,
    required this.uri,
    this.ahead = 0,
    this.behind = 0,
  }) : error = null;

  GitRemote.error({
    required this.name,
    this.branch = '<ERROR>',
    required this.uri,
    required this.error,
  })  : ahead = 0,
        behind = 0,
        assert(error != null);

  bool get isError => error != null;

  bool get isSync => !isError && ahead == 0 && behind == 0;

  @override
  String toString() {
    return 'GitRemote{name: $name, branch: $branch, uri: $uri, ahead: $ahead, behind: $behind, error: $error}';
  }
}
