import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/core/result.dart';

void main() {
  group('Result', () {
    test('Ok expone su valor y se marca como éxito', () {
      const result = Ok<int>(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.value, 42);
    });

    test('Err expone un Failure y se marca como error', () {
      const result = Err<int>(AuthFailure('Credenciales inválidas.'));

      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure.message, 'Credenciales inválidas.');
    });

    test('el switch exhaustivo distingue ambos casos', () {
      String describe(Result<void> result) => switch (result) {
        Ok() => 'ok',
        Err(:final failure) => failure.message,
      };

      expect(describe(const Ok(null)), 'ok');
      expect(describe(const Err(NetworkFailure('sin red'))), 'sin red');
    });
  });

  group('Failure', () {
    test('toString incluye el tipo y el mensaje', () {
      expect(
        const AuthFailure('x').toString(),
        'AuthFailure(x)',
      );
    });
  });
}
