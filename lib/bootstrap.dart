import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    super.didUpdateProvider(context, previousValue, newValue);
    final provider = context.provider;
    log('didUpdateProvider(${provider.name ?? provider.runtimeType}, $newValue)');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final provider = context.provider;
    log('providerDidFail(${provider.name ?? provider.runtimeType}, $error, $stackTrace)');
    super.providerDidFail(context, error, stackTrace);
  }
}
