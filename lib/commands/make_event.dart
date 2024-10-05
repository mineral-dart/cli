import 'dart:async';
import 'dart:io';

import 'package:commander_ui/commander_ui.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:recase/recase.dart';

final class MakeEvent with Tools implements CliCommandContract {
  @override
  String get name => 'make:event';

  @override
  String get description => 'Create a new event class';

  @override
  Future<void> handle(List<String> arguments) async {
    final formatter = DartFormatter(pageWidth: 150);

    final screen = AlternateScreen(title: 'Creating event…');
    screen.start();

    final event = await Select<Event>(
      answer: 'Choose your event to make it !',
      options: Event.values,
      onDisplay: (e) => e.value.toString(),
      placeholder: 'search…',
      onExit: () => screen.stop(),
    ).handle();

    final filename = arguments.firstOrNull?.snakeCase ??
        await Input(
          answer: 'Enter the event name',
          placeholder: 'Event',
          defaultValue: event.value.toString().replaceAll('Event', '').snakeCase,
          onExit: () => screen.stop(),
        ).handle();

    final className = filename.pascalCase;

    final location = await Select<Directory>(
      answer: 'Where would you like to create the event ?',
      options: Directory('src').listSync(recursive: true).whereType<Directory>().toList(),
      onDisplay: (e) => e.path,
      placeholder: 'search…',
      onExit: () => screen.stop(),
    ).handle();

    screen.stop();

    hideInput();

    final delayed = Delayed();

    delayed.step('Build event class…');

    final eventClass = _buildClass(className, event);
    final file = File('${location.path}/$filename.dart');

    delayed.step('Creating file…');

    try {
      await file.writeAsString(formatter.format(eventClass));
      delayed.success('Event created successfully in ${file.path}');

      await Future.delayed(Duration(seconds: 1), () => exit(0));
    } catch (error) {
      delayed.error('An error occurred while creating the file: $error');
    }

    showInput();
  }

  String _buildClass(String className, Event event) {
    return ClassBuilder()
        .setClassName(className)
        .setExtends(
            ParameterStruct(name: event.value.toString(), import: 'package:mineral/events.dart'))
        .addMethod(MethodStruct(
            name: 'handle',
            returnType: ParameterStruct(name: 'Future<void>', import: null),
            isOverride: true,
            isAsync: true,
            body: StringBuffer()..write('// Your code here'),
            parameters: event.parameters
                .map(
                    (element) => ParameterStruct(name: element, import: 'package:mineral/api.dart'))
                .toList()))
        .build();
  }
}
