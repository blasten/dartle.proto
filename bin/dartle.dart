#!/usr/bin/env dart

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartle/autogen/plugin.pb.dart';
import 'package:dartle/generator.dart';
import 'package:path/path.dart' as path;

class GenCommand extends Command {
  final name = 'gen';
  final description = 'Platform channel generator for .proto files.';

  GenCommand() {
    argParser.addOption(
      'out',
      abbr: 'o',
      help: 'The output directory where the files are generated',
    );
  }

  void run() async {
    if (!Platform.isMacOS) {
      print('This tool is only supported on MacOS');
      exit(1);
    }

    String outputOption = argResults['out'];
    if (outputOption == null) {
      throw UsageException(
        'Must specify the --out option',
        'Example: "pub run dartle_gen $name --out <destination> <input.proto>"',
      );
    }

    var outDirectory = Directory(outputOption);
    try {
      outDirectory.createSync(recursive: true);
    } on FileSystemException catch(_) {
      print('Failed to create directory ${outDirectory.path}');
    }

    if (argResults.rest.length != 1) {
      throw UsageException(
        'Must specify the input proto file',
        'Example: "pub run dartle_gen $name --out <destination> <input.proto>"',
      );
    }
    var protoFile = File(argResults.rest.first);
    try {
      if (!protoFile.existsSync()) {
        print('Could not find proto files at location ${protoFile.path}');
        exit(1);
      }
    } on FileSystemException catch(_) {
      print('Failed to read file ${protoFile.path}');
    }

    var protocBinary = path.join(path.dirname(Platform.script.path), 'osx_x86_64', 'protoc');
    var protocPlugin = path.join(path.dirname(Platform.script.path), 'protoc_plugin');
    var protosPath = path.join(path.dirname(path.dirname(Platform.script.path)), 'protos');
    var result = await Process.run(
      protocBinary, [
        path.basename(protoFile.path),
        '--proto_path', protoFile.parent.absolute.path,
        '--proto_path', protosPath,
        '--plugin', 'protoc-gen-custom=$protocPlugin',
        '--custom_out', outDirectory.absolute.path,
      ]);

    if (result.exitCode != 0) {
      print('The protoc compiler exited with errors:\n${result.stderr}');
      exit(1);
    }
    print('Protos compiled successfully!');
  }
}

class ProtoCPluginCommand extends Command {
  final name = 'protoc_plugin';
  final description = 'The protoc plugin that takes the proto AST.';

  ProtoCPluginCommand();

  void run() async {
    var request = CodeGeneratorRequest()..mergeFromBuffer(await stdin.first);
    var response = CodeGeneratorResponse();
    var generator = CodeGenerator(
      request: request,
      response: response,
    );

    generator.generate();
    stdout.write(String.fromCharCodes(response.writeToBuffer()));
  }
}

void main(List<String> args) async {
  final CommandRunner runner = CommandRunner(
    'dartle_gen',
    'Code generator for .proto files to work with Platform channels.',
  )
  ..addCommand(GenCommand())
  ..addCommand(ProtoCPluginCommand());

  try {
    await runner.run(args);
  } on UsageException catch (error) {
    print(error);
  }
}
