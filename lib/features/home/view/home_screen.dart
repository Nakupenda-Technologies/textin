import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/env/env.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_style.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Env.appName),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Env.isProd
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                Env.flavor.name.toUpperCase(),
                style: TextStyle(
                  color: Env.isProd ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeError) {
            return Center(
              child: Text('Error: ${state.message}', style: AppTextStyle.body),
            );
          }
          if (state is HomeLoaded) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to ${Env.appName}',
                    style: AppTextStyle.heading1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Environment: ${Env.environment}',
                    style: AppTextStyle.bodySecondary,
                  ),
                  Text(
                    'API Base URL: ${Env.baseUrl}',
                    style: AppTextStyle.bodySecondary,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primaryLight.withValues(
                              alpha: 0.2,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.profile.name,
                                style: AppTextStyle.heading3,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                state.profile.status,
                                style: AppTextStyle.bodySecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
