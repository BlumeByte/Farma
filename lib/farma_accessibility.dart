import 'package:material_ui/material_ui.dart';

class FarmaAccessibility extends InheritedWidget {
  const FarmaAccessibility({
    required this.enabled,
    required this.onChanged,
    required super.child,
    super.key,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  static FarmaAccessibility? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FarmaAccessibility>();

  static bool isEnabled(BuildContext context) =>
      maybeOf(context)?.enabled ?? false;

  @override
  bool updateShouldNotify(FarmaAccessibility oldWidget) =>
      enabled != oldWidget.enabled;
}

class AccessibilityModeButton extends StatelessWidget {
  const AccessibilityModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibility = FarmaAccessibility.maybeOf(context);
    if (accessibility == null) return const SizedBox.shrink();
    final enabled = accessibility.enabled;
    final colorScheme = Theme.of(context).colorScheme;
    const label = 'Accessibility mode';
    final background = enabled ? colorScheme.primaryContainer : null;
    void toggle() {
      accessibility.onChanged(!enabled);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              enabled ? 'Accessibility mode off.' : 'Accessibility mode on.',
            ),
          ),
        );
    }

    if (MediaQuery.sizeOf(context).width >= 640) {
      return Semantics(
        toggled: enabled,
        child: TextButton.icon(
          onPressed: toggle,
          style: TextButton.styleFrom(backgroundColor: background),
          icon: const Icon(Icons.accessibility_new),
          label: const Text(label),
        ),
      );
    }
    return Semantics(
      toggled: enabled,
      child: IconButton(
        tooltip: label,
        icon: const Icon(Icons.accessibility_new),
        isSelected: enabled,
        style: IconButton.styleFrom(backgroundColor: background),
        onPressed: toggle,
      ),
    );
  }
}

class FarmaHeading extends StatelessWidget {
  const FarmaHeading(
    this.text, {
    this.style,
    this.textAlign,
    this.announce = false,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool announce;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    header: true,
    liveRegion: announce && FarmaAccessibility.isEnabled(context),
    child: Text(text, style: style, textAlign: textAlign),
  );
}

class AccessibilityGuide extends StatelessWidget {
  const AccessibilityGuide(this.instructions, {super.key});

  final String instructions;

  @override
  Widget build(BuildContext context) {
    if (!FarmaAccessibility.isEnabled(context)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(instructions),
    );
  }
}
