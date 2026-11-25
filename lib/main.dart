import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'farma_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Expose the website to screen readers from its first frame.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  runApp(const FarmaApp());
}
