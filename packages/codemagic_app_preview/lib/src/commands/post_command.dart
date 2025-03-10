import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:codemagic_app_preview/src/builds/artifact_links_parser.dart';
import 'package:codemagic_app_preview/src/comment/comment_builder.dart';
import 'package:codemagic_app_preview/src/comment/comment_poster.dart';
import 'package:codemagic_app_preview/src/environment_variable/environment_variable_accessor.dart';
import 'package:codemagic_app_preview/src/github/git_repo.dart';
import 'package:codemagic_app_preview/src/github/github_api_repository.dart';
import 'package:http/http.dart';

class PostCommand extends Command {
  PostCommand({
    Client? httpClient,
    this.environmentVariableAccessor =
        const SystemEnvironmentVariableAccessor(),
    this.gitRepo = const GitRepo(),
  }) : this.httpClient = httpClient ?? Client() {
    argParser..addOption('gh_token', abbr: 't');
    argParser
      ..addOption(
        'message',
        abbr: 'm',
        help: 'A custom message that can be added to the comment.',
      );
  }

  final Client httpClient;
  final EnvironmentVariableAccessor environmentVariableAccessor;
  final GitRepo gitRepo;

  @override
  String get description =>
      'Post a new comment or edits the existing comment with the links to the app previews';

  @override
  String get name => 'post';

  Future<void> run() async {
    final String? githubToken = argResults?['gh_token'];
    if (githubToken == null) {
      stderr.writeln(
          'The GitHub access token is not set. Please set the token with the --gh_token option.');
      exitCode = 1;
      return;
    }
    final String? message = argResults?['message'];

    final builds = ArtifactLinksParser(environmentVariableAccessor).getBuilds();

    final comment = CommentBuilder(environmentVariableAccessor).build(
      builds,
      message: message,
    );
    final owner = await gitRepo.getOwner();
    final repoName = await gitRepo.getRepoName();
    final gitHubApi = GitHubApiRepository(
      token: githubToken,
      httpClient: httpClient,
      owner: owner,
      repository: repoName,
    );

    final pullRequestId =
        environmentVariableAccessor.get('CM_PULL_REQUEST_NUMBER');
    await CommentPoster(gitHubApi)
        .post(comment: comment, pullRequestId: pullRequestId);
  }
}
