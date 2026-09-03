import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../config/env/env.dart';
import '../core/di/locator.dart';
import '../core/theme/app_theme.dart';
import '../features/home/cubit/home_cubit.dart';
import '../features/texting/cubit/inbox/inbox_cubit.dart';
import '../router/app_router.dart';

class TextinApp extends StatelessWidget {
  const TextinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<InboxCubit>(
          create: (_) => locator<InboxCubit>()..loadConversations(),
        ),
        BlocProvider<HomeCubit>(
          create: (_) => locator<HomeCubit>()..loadProfile(),
        ),
      ],
      child: MaterialApp(
        title: Env.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.inbox,
      ),
    );
  }
}
