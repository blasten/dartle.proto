
import 'package:meta/meta.dart';

import 'autogen/plugin.pb.dart';

class CodeGenerator {
  CodeGenerator({
    @required this.request,
    @required this.response,
  }) : assert(request != null),
       assert(response != null);

  final CodeGeneratorRequest request;
  final CodeGeneratorResponse response;

  /// Generates the code.
  void generate() {
    var file = CodeGeneratorResponse_File();

    file.name = 'foo.dart';
    file.content = 'yay';
    response.file.add(file);
  }
}