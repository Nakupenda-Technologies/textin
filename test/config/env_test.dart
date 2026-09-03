import 'package:flutter_test/flutter_test.dart';
import 'package:textin/config/env/env.dart';

void main() {
  group('Env flavor tests', () {
    test('Dev flavor sets correct properties', () {
      Env.setFlavor(Flavor.dev);
      expect(Env.flavor, Flavor.dev);
      expect(Env.isDev, isTrue);
      expect(Env.isStaging, isFalse);
      expect(Env.isProd, isFalse);
      expect(Env.appName, 'Textin Dev');
      expect(Env.baseUrl, contains('nakupendaapp.com/dev/api/v1'));
      expect(Env.messagingBaseUrl, contains('nakupendaapp.com/dev/api'));
      expect(Env.websocketBaseUrl, 'wss://nakupendaapp.com');
    });

    test('Staging flavor sets correct properties', () {
      Env.setFlavor(Flavor.staging);
      expect(Env.flavor, Flavor.staging);
      expect(Env.isDev, isFalse);
      expect(Env.isStaging, isTrue);
      expect(Env.isProd, isFalse);
      expect(Env.appName, 'Textin Staging');
      expect(Env.baseUrl, contains('nakupendaapp.com/staging/api/v1'));
      expect(Env.messagingBaseUrl, contains('nakupendaapp.com/staging/api'));
    });

    test('Prod flavor sets correct properties', () {
      Env.setFlavor(Flavor.prod);
      expect(Env.flavor, Flavor.prod);
      expect(Env.isDev, isFalse);
      expect(Env.isStaging, isFalse);
      expect(Env.isProd, isTrue);
      expect(Env.appName, 'Textin');
      expect(Env.baseUrl, 'https://nakupendaapp.com/api/v1');
      expect(Env.messagingBaseUrl, 'https://nakupendaapp.com/api');
    });
  });
}
