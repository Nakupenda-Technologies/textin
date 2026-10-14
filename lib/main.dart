import 'package:flutter/services.dart';

import 'config/env/env.dart';
import 'main_common.dart';

void main() async {
  Env.setFlavor(Flavor.values.asNameMap()[appFlavor] ?? Flavor.prod);
  await mainCommon();
}
