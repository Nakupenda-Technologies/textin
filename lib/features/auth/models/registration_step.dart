enum RegistrationStep {
  accountType('account_type_selection'),
  basicInfo('basic_info'),
  passwordSetup('password_setup'),
  ageGender('age_gender'),
  themeSelection('theme_selection'),
  creatorMode('creator_mode_toggle'),
  currents('currents_selection');

  const RegistrationStep(this.key);

  final String key;

  static RegistrationStep? fromKey(Object? key) {
    for (final step in values) {
      if (step.key == key) return step;
    }
    return null;
  }
}

class StepResult {
  const StepResult({this.nextStep, this.rawNextStep});

  final RegistrationStep? nextStep;
  final String? rawNextStep;

  bool get isFinished => rawNextStep == null;

  static StepResult fromJson(Object? json) {
    final source = json is Map<String, dynamic>
        ? (json['data'] is Map<String, dynamic>
              ? json['data'] as Map<String, dynamic>
              : json)
        : const <String, dynamic>{};
    final raw = source['nextStep'];
    final rawNextStep = raw is String && raw.isNotEmpty ? raw : null;
    return StepResult(
      nextStep: RegistrationStep.fromKey(rawNextStep),
      rawNextStep: rawNextStep,
    );
  }
}

class ProcessTracker {
  const ProcessTracker({
    required this.processId,
    required this.step,
    this.flowKey,
    this.status,
  });

  final String processId;
  final StepResult step;
  final String? flowKey;
  final String? status;

  bool get isExpired => status == 'expired';

  static ProcessTracker? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final source = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final processId = source['processId'];
    if (processId is! String || processId.isEmpty) return null;

    final flowKey = source['flowKey'];
    final status = source['status'];
    return ProcessTracker(
      processId: processId,
      step: StepResult.fromJson(source),
      flowKey: flowKey is String ? flowKey : null,
      status: status is String ? status : null,
    );
  }
}
