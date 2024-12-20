import 'package:mineral_cli/src/infrastructure/builder/class/method_struct.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/parameter_struct.dart';
import 'package:mineral_cli/src/infrastructure/builder/class/property_struct.dart';

final class ClassBuilder {
  bool isAbstract = false;
  bool isInterface = false;
  final List<String> imports = [];
  final List<ParameterStruct> implements = [];
  final List<ParameterStruct> mixins = [];
  final List<List<PropertyStruct>> constructors = [];
  final List<StringBuffer> constructorBody = [];
  final List<MethodStruct> methods = [];
  final List<PropertyStruct> properties = [];

  String? className;
  ParameterStruct? extension;

  ClassBuilder setClassName(String className) {
    this.className = className;
    return this;
  }

  ClassBuilder setAbstract(bool value) {
    isAbstract = value;
    return this;
  }

  ClassBuilder setInterface(bool value) {
    isInterface = value;
    return this;
  }

  ClassBuilder setExtends(ParameterStruct struct) {
    extension = struct;

    if (struct.import case final String value when !imports.contains(value)) {
      imports.add(value);
    }

    return this;
  }

  ClassBuilder addImplement(ParameterStruct struct) {
    implements.add(struct);

    if (struct.import case final String value when !imports.contains(value)) {
      imports.add(value);
    }

    return this;
  }

  ClassBuilder addProperty(PropertyStruct property) {
    properties.add(property);

    if (property.returnType?.import case final String value
        when !imports.contains(value)) {
      imports.add(value);
    }

    return this;
  }

  ClassBuilder addConstructor(List<PropertyStruct> properties,
      {StringBuffer? body}) {
    constructors.add(properties);

    for (final property in properties) {
      addProperty(PropertyStruct(
        name: property.name,
        isFinal: property.isFinal,
        returnType: property.returnType,
      ));

      if (property.returnType?.import case final String value
          when !imports.contains(value)) {
        imports.add(value);
      }
    }

    return this;
  }

  ClassBuilder addBodyConstructor(StringBuffer body) {
    constructorBody.add(body);
    return this;
  }

  ClassBuilder addMethod(MethodStruct method) {
    methods.add(method);

    final imports = [
      method.returnType.import,
      ...method.parameters.map((parameter) => parameter.import)
    ];
    for (final import in imports) {
      if (import case final String value when !this.imports.contains(value)) {
        this.imports.add(value);
      }
    }

    return this;
  }

  ClassBuilder addMixin(ParameterStruct struct) {
    mixins.add(struct);

    if (struct.import case final String value when !imports.contains(value)) {
      imports.add(value);
    }

    return this;
  }

  String build() {
    final buffer = StringBuffer();

    for (final import in imports) {
      buffer.write("import '$import';");
    }

    buffer.writeln();
    if (isAbstract) {
      buffer.write('abstract ');
    }

    if (isInterface) {
      buffer.write('interface ');
    }

    if (!(isAbstract && isInterface)) {
      buffer.write('final ');
    }

    buffer.write('class $className');

    if (extension case ParameterStruct(:final name)) {
      buffer.write(' extends $name');
    }

    if (mixins.isNotEmpty) {
      buffer
        ..write(' with ')
        ..write(mixins.map((element) => element.name).join(', '));
    }

    if (implements.isNotEmpty) {
      buffer
        ..write(' implements ')
        ..write(implements.map((element) => element.name).join(', '));
    }

    buffer.write(' {');
    buffer.writeln();

    for (final property in properties) {
      if (property.isOverride) {
        buffer.writeln('  @override');
      }

      buffer.write('  ');
      if (property.isStatic) {
        buffer.write('static ');
      }

      if (property.isFinal) {
        buffer.write('final ');
      }

      if (property.isGetter) {
        buffer.write(
            '${property.returnType?.name} get ${property.name} => ${property.name};');
      } else if (property.isSetter) {
        buffer.write(
            'set ${property.name}(${property.returnType?.name} value) => ${property.name} = value;');
      } else {
        buffer.write('${property.returnType?.name} ${property.name}');
      }

      if (property.value != null) {
        buffer.write(' = ${property.value};');
      } else {
        buffer.write(';');
      }
    }

    buffer.writeln();
    buffer.writeln();

    for (final constructor in constructors) {
      buffer.writeln('$className(');
      buffer.write(
          constructor.map((property) => 'this.${property.name}').join(', '));
      buffer.write(')');
      if (constructorBody.isEmpty) {
        buffer.write(';');
      }
    }

    if (constructorBody.isNotEmpty) {
      buffer.write(' {');
      for (final constructorBody in constructorBody) {
        buffer.writeln(constructorBody);
      }
      buffer.write('  }');
    }

    buffer.writeln();
    buffer.writeln();

    for (final method in methods) {
      if (method.isOverride) {
        buffer.writeln('@override');
      }

      buffer.write('${method.returnType.name} ${method.name}(');

      final parameters = method.parameters.map((parameter) => parameter.name);
      buffer
        ..write(parameters.join(', '))
        ..write(')');

      if (method.isAsync) {
        buffer.write(' async');
      }

      buffer.write(' {');
      if (method.body != null) {
        buffer.writeln(method.body.toString());
      }
      buffer.write('  }');

      buffer.writeln();
    }

    buffer.write('}');
    buffer.writeln();

    return buffer.toString();
  }
}
