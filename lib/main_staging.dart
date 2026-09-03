import 'config/env/env.dart';
import 'main_common.dart';

void main() async {
  Env.setFlavor(Flavor.staging);
  await mainCommon();
}
