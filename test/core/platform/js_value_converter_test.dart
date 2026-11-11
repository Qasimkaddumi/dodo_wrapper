import 'package:dodo_wrapper/src/core/platform/js_value_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes nested maps and lists', () {
    final input = <Object?, Object?>{
      1: [
        <Object?, Object?>{'a': true},
      ],
      'b': null,
    };
    expect(toJsonMap(input), {
      '1': [
        {'a': true},
      ],
      'b': null,
    });
  });

  test('returns an empty map for anything but a map', () {
    expect(toJsonMap(null), isEmpty);
    expect(toJsonMap('text'), isEmpty);
    expect(toJsonMap([1]), isEmpty);
  });
}
