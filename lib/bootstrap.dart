import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    super.didUpdateProvider(provider, previousValue, newValue, container);
    log('didUpdateProvider(${provider.name ?? provider.runtimeType}, $newValue)');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    log('providerDidFail(${provider.name ?? provider.runtimeType}, $error, $stackTrace)');
    super.providerDidFail(provider, error, stackTrace, container);
  }
}
