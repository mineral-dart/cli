import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral_cli/mineral_cli.dart';
import 'package:mineral_cli/src/domain/contracts/cli_command_contract.dart';
import 'package:mineral_cli/src/domain/entities/cli_command.dart';
import 'package:recase/recase.dart';

final class MakeProvider implements CliCommandContract {
  final _commander = Commander();

  final emitter = DartEmitter();
  final formatter = DartFormatter(
      pageWidth: 150, languageVersion: DartFormatter.latestLanguageVersion);

  @override
  String get name => 'make:provider';

  @override
  String get description => 'Create a new provider entrypoint';

  @override
  Future<void> handle(List<MineralCommand> _, List<String> arguments) async {
    final formatter = DartFormatter(pageWidth: 80);

    final filename = arguments.firstOrNull?.snakeCase ??
        await _commander.ask<String>(
          'Enter the provider name',
          validate: (validator) => validator.notEmpty(),
        );

    final className = '${filename.pascalCase}Provider';

    final libDirectoryHasFolders = Directory('lib')
        .listSync(recursive: true)
        .whereType<Directory>()
        .isNotEmpty;

    final location = !libDirectoryHasFolders
        ? Directory('lib')
        : await _commander.select<Directory>(
            'Where would you like to create the provider ?',
            options: Directory('lib')
                .listSync(recursive: true)
                .whereType<Directory>()
                .toList(),
            onDisplay: (e) => e.path,
            placeholder: 'search…',
          );

    final task = await _commander.task();
    final clazz = await task.step('Building event class…', callback: () {
      return Library((library) => library
        ..body.addAll([
          Code('import \'package:mineral/api.dart\';'),
          Class((clazz) => clazz
            ..name = className.pascalCase
            ..extend = refer('Provider', 'package:mineral/api.dart')
            ..constructors.add(Constructor((constructor) => constructor
              ..body = Code('// client.register(...);\n')
              ..requiredParameters.addAll([
                Parameter((parameter) => parameter
                  ..name = 'client'
                  ..type = refer('Client', 'package:mineral/api.dart'))
              ]))))
        ]));
    });

    try {
      final file =
          await task.step('Building provider class…', callback: () async {
        final file = File('${location.path}/${filename}_provider.dart');
        final content = formatter.format(clazz.accept(emitter).toString());
        await file.writeAsString(content);

        return file;
      });

      task.success('Provider created successfully in ${file.path}');
      _commander.warn('Don\'t forget to register your provider in the client.');
    } catch (error) {
      task.error('An error occurred while creating the file: $error');
    }
  }
}
