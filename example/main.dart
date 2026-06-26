import 'dart:io';

import 'package:path/path.dart' as p;

void main() {
  final rootObservabilityDir = p.normalize(
    p.join('..', 'lib', 'observability'),
  );

  stdout.writeln('Data Fight Central example workspace is healthy.');
  stdout.writeln('Observability helpers live under: $rootObservabilityDir');
  stdout.writeln(
    'This placeholder example stays dependency-safe so root Flutter tooling can run cleanly.',
  );
}
