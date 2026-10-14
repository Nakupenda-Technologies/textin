import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/storage/session_store.dart';
import 'package:textin/features/auth/data_source/auth_remote_data_source.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/models/current_item.dart';
import 'package:textin/features/auth/models/registration_step.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  Failure? loginFailure;
  Failure? fetchMeFailure;
  Failure? stepFailure;
  bool usernameAvailable = true;
  String processStatus = 'in_progress';
  String processFlowKey = 'onboarding_personal';
  RegistrationStep? resumeStep = RegistrationStep.passwordSetup;
  List<CurrentItem> currents = const [
    CurrentItem(id: 'c1', name: 'Music'),
    CurrentItem(id: 'c2', name: 'Travel'),
  ];

  final List<({RegistrationStep step, Map<String, dynamic> payload})>
  submittedSteps = [];
  final List<String> deletedProcesses = [];
  final List<String> completedProcesses = [];

  static const user = AuthUser(
    id: 'user-1',
    username: 'slim',
    firstName: 'Slim',
    lastName: 'Shady',
  );

  static const _nextStep = {
    RegistrationStep.accountType: RegistrationStep.basicInfo,
    RegistrationStep.basicInfo: RegistrationStep.passwordSetup,
    RegistrationStep.passwordSetup: RegistrationStep.ageGender,
    RegistrationStep.ageGender: RegistrationStep.themeSelection,
    RegistrationStep.themeSelection: RegistrationStep.creatorMode,
    RegistrationStep.creatorMode: RegistrationStep.currents,
  };

  @override
  Future<AuthTokens> login({
    required String identifier,
    required String password,
  }) async {
    if (loginFailure case final failure?) throw failure;
    return const AuthTokens(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<AuthUser> fetchMe() async {
    if (fetchMeFailure case final failure?) throw failure;
    return user;
  }

  @override
  Future<ProcessTracker> startProcess({
    required String flowKey,
    required String deviceId,
  }) async => ProcessTracker(
    processId: 'process-1',
    flowKey: flowKey,
    status: 'in_progress',
    step: const StepResult(
      nextStep: RegistrationStep.accountType,
      rawNextStep: 'account_type_selection',
    ),
  );

  @override
  Future<ProcessTracker> getProcess(String processId) async => ProcessTracker(
    processId: processId,
    flowKey: processFlowKey,
    status: processStatus,
    step: StepResult(nextStep: resumeStep, rawNextStep: resumeStep?.key),
  );

  @override
  Future<({StepResult step, AuthTokens? tokens})> submitStep(
    String processId,
    RegistrationStep step,
    Map<String, dynamic> payload,
  ) async {
    if (stepFailure case final failure?) throw failure;
    submittedSteps.add((step: step, payload: payload));
    final next = _nextStep[step];
    return (
      step: StepResult(nextStep: next, rawNextStep: next?.key),
      tokens: step == RegistrationStep.passwordSetup
          ? const AuthTokens(accessToken: 'new-access', refreshToken: 'r')
          : null,
    );
  }

  @override
  Future<void> deleteProcess(String processId) async =>
      deletedProcesses.add(processId);

  @override
  Future<void> completeProcess(String processId) async =>
      completedProcesses.add(processId);

  @override
  Future<bool> isUsernameAvailable(String username) async => usernameAvailable;

  @override
  Future<List<CurrentItem>> fetchCurrents() async => currents;
}
