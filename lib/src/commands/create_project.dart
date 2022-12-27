import 'dart:io';

import 'package:mineral_cli/src/exceptions/already_exist_exception.dart';
import 'package:mineral_cli/src/exceptions/missing_argument_exception.dart';
import 'package:mineral_cli/src/cli_command.dart';
import 'package:mineral_console/mineral_console.dart';
import 'package:path/path.dart';
import 'package:recase/recase.dart';

class CreateProject extends CliCommand {
  CreateProject(Console console): super(console, 'create', 'Create new mineral project', ['name']);

  @override
  Future<void> handle(Map args) async {
    if (args.length == 1) {
      throw MissingArgumentException('name');
    }

    String filename = ReCase(args['name']).snakeCase;

    final projectDirectory = Directory(join(Directory.current.path, filename));

    ProcessResult process = await Process.run('git', ['clone', 'https://github.com/mineral-dart/base-structure.git', filename.snakeCase]);

    switch (process.exitCode) {
      case 0:
        final gitDirectory = Directory(join(projectDirectory.path, '.git'));
        await gitDirectory.delete(recursive: true);

        print('Project $filename has been created at the following location ${projectDirectory.uri}'.green());
        break;
      case 128:
        throw AlreadyExistException(projectDirectory.uri);
      default: {
        print(process.stderr);
      }
    }
  }
}
