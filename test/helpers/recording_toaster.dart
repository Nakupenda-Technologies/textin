import 'package:textin/shared/widgets/app_toast.dart';

class RecordingToaster extends Toaster {
  final List<String> infos = [];
  final List<({String title, String message})> errors = [];

  @override
  void info(String message) => infos.add(message);

  @override
  void error(String title, String message) =>
      errors.add((title: title, message: message));
}
