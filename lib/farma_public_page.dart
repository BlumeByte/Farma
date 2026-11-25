import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import 'farma_accessibility.dart';

typedef FarmaSection = ({String title, String body});
typedef FarmaStory = ({
  String title,
  String caption,
  String file,
  String image,
  List<String> steps,
});

class FarmaPageContent {
  const FarmaPageContent({
    required this.heading,
    required this.intro,
    this.image,
    this.imageDescription,
    this.example,
    required this.questions,
    required this.sectionHeading,
    required this.sections,
    this.stories = const [],
  });

  final String heading;
  final String intro;
  final String? image;
  final String? imageDescription;
  final ({String title, List<(String, String)> rows})? example;
  final List<(String, String)> questions;
  final String sectionHeading;
  final List<FarmaSection> sections;
  final List<FarmaStory> stories;
}

const _fieldImage = 'assets/farma/field.webp';
const _produceImage = 'assets/farma/produce.webp';
const _fieldPhoto = 'Illustration of a Ghanaian farmer examining a cocoa pod';
const _producePhoto =
    'Illustration of freshly harvested produce in woven baskets';

const _fieldStory = (
  title: 'From field observation to follow-up',
  caption: 'A short introduction to documenting a field visit and returning to the record.',
  file: 'assets/farma/field-walkthrough.mp4',
  image: _fieldImage,
  steps: [
    'Photograph the observation. Capture a clear image during your field visit.',
    'Add context. Record a title, category and notes.',
    'Reopen the record. Compare what you observe on your next visit.',
  ],
);

const _marketStory = (
  title: 'Preparing a produce listing',
  caption: 'A walkthrough of saving a local draft before writing a listing for buyers.',
  file: 'assets/farma/produce-walkthrough.mp4',
  image: _produceImage,
  steps: [
    'Name the produce. Start with the crop or item you harvested.',
    'Add a representative photo. Choose an image that shows the produce clearly.',
    'Review your draft. Check the details and save them on your device.',
  ],
);

const farmaPages = {
  'home': FarmaPageContent(
    heading: 'Keep track of what happens in the field.',
    intro: 'Save a photo and a note when you spot a change on the farm. When you have produce to sell, publish a listing that signed-in buyers can find.',
    image: _fieldImage,
    imageDescription: _fieldPhoto,
    sectionHeading: 'From a field visit to a listing',
    sections: [
      (
        title: 'Record what you saw',
        body: 'Add a date, category and short note. A title like “Yellow leaves in the north tomato bed” is easier to find later than “Tomatoes”.',
      ),
      (
        title: 'Review it on the next visit',
        body: 'Open a saved observation on the same device. Compare the photo and notes with what you see on the next visit.',
      ),
      (
        title: 'Prepare a listing for buyers',
        body: 'Start in Produce and save a draft. When you publish it, write a description for buyers. Choose whether to share the draft photo. Private notes stay on your device.',
      ),
      (
        title: 'Browse in Buyer Mode',
        body: 'Switch to Buyer Mode to search the latest published produce by name or category and open the listing details.',
      ),
    ],
    questions: [
      ('Do I need an account?', 'The website is open to everyone. Sign in to save field records, publish produce or browse the marketplace.'),
      ('Can I open my observations on another phone?', 'Field observations and drafts stay on the device where you saved them. Published listings can be seen from other devices after sign-in.'),
    ],
  ),
  'about': FarmaPageContent(
    heading: 'About us',
    intro: 'Farma is a BlumeByte project based in Accra, Ghana. It grew out of a practical problem for farmers, buyers and field teams. Useful details can get lost between a field visit, a follow-up and a sale.',
    image: _produceImage,
    imageDescription: _producePhoto,
    sectionHeading: 'The problems we are working on',
    sections: [
      (
        title: 'Keep field details together',
        body: 'Photos are more useful when they have a date, a location you recognize and a note about what changed. Use the title or note for the plot name and revisit the record when you return.',
      ),
      (
        title: 'Give buyers a clear starting point',
        body: 'A published listing tells buyers what is available and what the farmer chose to share. Clear descriptions make it easier to compare listings.',
      ),
      (
        title: 'Design for the device people have',
        body: 'Farma runs on the web and is built for Android and iOS. The application supports device light and dark settings, reduced motion and a mode for screen reader users.',
      ),
      (
        title: 'Plan for weak connectivity',
        body: 'Saved local records can be reopened once the workspace is loaded. Signing in and using the marketplace need internet access. Device sync and broader offline support are planned.',
      ),
    ],
    questions: [
      ('Who builds Farma?', 'Farma is a product of BlumeByte Digital Solution in Accra, Ghana.'),
      ('How are field teams involved?', 'Current records can support a conversation with a field worker. A shared reviewer workspace and district reporting are planned.'),
    ],
  ),
  'profile': FarmaPageContent(
    heading: 'Profile',
    intro: 'Get to know the Farma project, the people it is built for and what happens to the information they enter.',
    example: (
      title: 'Project profile',
      rows: [
        ('Product', 'Farma'),
        ('Team', 'BlumeByte Digital Solution'),
        ('Based in', 'Accra, Ghana'),
        ('Workspaces', 'Farmer Mode and Buyer Mode'),
      ],
    ),
    sectionHeading: 'Accounts, language and records',
    sections: [
      (
        title: 'Sign up with your own number',
        body: 'Choose your country or territory, add your international phone number and choose a unique username. Return to Farma using your email and password.',
      ),
      (
        title: 'Set a language preference',
        body: 'Sign-in supports nine languages. In the workspace, choose a preferred language or enter another language or dialect. Some workspace screens still appear in English.',
      ),
      (
        title: 'Know what buyers can see',
        body: 'Publishing shares the produce name, category and buyer-facing description with signed-in buyers. Buyers can also see a photo if you choose to share it. Private notes stay on the device.',
      ),
      (
        title: 'Keep account and trial data in view',
        body: 'Account details are handled by Supabase. Local observations and drafts are stored separately for each account on that device. Marketplace listings are stored online.',
      ),
    ],
    questions: [
      ('Does the phone number replace my email?', 'Use your email and password to sign in. The phone number is part of your account profile.'),
      ('Can I change modes later?', 'Yes. Use Change mode in the workspace to return to the Farmer and Buyer options.'),
    ],
  ),
  'projects': FarmaPageContent(
    heading: 'Projects',
    intro: 'See what Farma is building and what the trial already supports. The field workspace and produce marketplace are the current focus. District operations and professional review are planned.',
    example: (
      title: 'Project status',
      rows: [
        ('Field workspace', 'Local observations and produce drafts'),
        ('Marketplace', 'Listings for signed-in buyers'),
        ('District operations', 'Planned'),
      ],
    ),
    sectionHeading: 'Current work and pilot plans',
    sections: [
      (
        title: 'Field workspace',
        body: 'Create, reopen and edit dated observations and produce drafts. The record stays with your account on the device where you saved it.',
      ),
      (
        title: 'Produce marketplace',
        body: 'A farmer can preview, publish or withdraw a listing and choose whether to share a photo. Buyers can browse and search the latest listings. Seller profiles and messaging are future work.',
      ),
      (
        title: 'District pilot concept',
        body: 'The project brief describes a possible district pilot to test training, field workflows and follow-up. Review queues, reporting and maps depend on partner validation.',
      ),
      (
        title: 'Farm Assistant',
        body: 'The workspace includes a screen for agricultural questions and photo assessments. Live responses require backend configuration. Professional review and escalation workflows are planned.',
      ),
    ],
    questions: [
      ('Can a field officer review my record in Farma today?', 'The current trial opens local records on your device. A shared review queue is outside this release.'),
      ('Are buyer payments and delivery available?', 'The current marketplace supports discovery. Payments and delivery remain planned.'),
    ],
    stories: [_marketStory],
  ),
  'services': FarmaPageContent(
    heading: 'Services',
    intro: 'Learn how to save an observation, publish produce and find a listing. Start with the task you want to complete.',
    example: (
      title: 'Example observation',
      rows: [
        ('Title', 'Yellow leaves in the north tomato bed'),
        ('Category', 'Crop'),
        ('Note', 'Spotted on the lower leaves during the morning visit.'),
        ('Next step', 'Reopen the record on the next visit.'),
      ],
    ),
    sectionHeading: 'How to use Farma',
    sections: [
      (
        title: 'Save an observation',
        body: 'Open Farmer Mode, choose Observations, then New observation. Enter a title and category, add a photo or note, and save it to this device.',
      ),
      (
        title: 'Publish or withdraw produce',
        body: 'Create a draft in Produce. Open its listing controls, enter a buyer-facing description and publish. Use Withdraw when the listing is no longer available.',
      ),
      (
        title: 'Search for produce',
        body: 'Open Buyer Mode and search by produce name or category. Open a result to read the description. Use Refresh to check for newly published listings.',
      ),
      (
        title: 'Use accessibility controls',
        body: 'Open Accessibility mode from the top bar. If you use a screen reader, photo descriptions and labeled navigation help you move through the workspace. Add descriptions to saved photos when they are useful.',
      ),
    ],
    questions: [
      ('What if camera access is denied?', 'Choose a photo from your device instead. You can also save an observation with a title and notes.'),
      ('Can I use Farma to confirm a crop or animal disease?', 'Use observations to keep track of what you see. The assistant, when configured, can offer preliminary guidance. Contact a qualified extension officer or veterinarian when you need a diagnosis.'),
    ],
    stories: [_fieldStory],
  ),
};

class FarmaPublicPage extends StatelessWidget {
  const FarmaPublicPage({
    required this.content,
    required this.isHome,
    required this.onSignIn,
    required this.onExplore,
    required this.onNavigate,
    super.key,
  });

  final FarmaPageContent content;
  final bool isHome;
  final VoidCallback onSignIn;
  final VoidCallback onExplore;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, viewport) {
        final wide = viewport.maxWidth >= 900;
        final padding = wide ? 48.0 : 20.0;
        final image = content.image == null
            ? _PageExample(example: content.example!)
            : AspectRatio(
          aspectRatio: wide ? 1.2 : 1.55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              content.image!,
              fit: BoxFit.cover,
              semanticLabel: content.imageDescription,
            ),
          ),
        );
        final lead = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FarmaHeading(
              content.heading,
              announce: true,
              style:
                  (wide
                          ? theme.textTheme.displayLarge
                          : theme.textTheme.displaySmall)
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: wide ? -2.4 : -1.2,
                      ),
            ),
            const SizedBox(height: 20),
            Text(
              content.intro,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.55),
            ),
            const AccessibilityGuide(
              'Turn on your device’s screen reader to hear headings, controls, and image descriptions. On a keyboard, Tab moves between controls and Enter activates them.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: onSignIn,
                  child: const Text('Open Farma'),
                ),
                if (isHome)
                  OutlinedButton(
                    onPressed: onExplore,
                    child: const Text('Explore services'),
                  ),
              ],
            ),
          ],
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, wide ? 54 : 28, padding, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      Row(
                        children: [
                          Expanded(child: lead),
                          const SizedBox(width: 48),
                          Expanded(child: image),
                        ],
                      )
                    else ...[
                      lead,
                      const SizedBox(height: 28),
                      image,
                    ],
                    const SizedBox(height: 56),
                    const Divider(),
                    const SizedBox(height: 28),
                    FarmaHeading(
                      content.sectionHeading,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    for (final section in content.sections) ...[
                      const Divider(height: 32),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FarmaHeading(
                                section.title,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                section.body,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (content.stories.isNotEmpty) ...[
                      const SizedBox(height: 50),
                      FarmaHeading(
                        'See how it works',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (_, layout) {
                          final width = wide
                              ? (layout.maxWidth - 16) / 2
                              : layout.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 20,
                            children: [
                              for (final story in content.stories)
                                SizedBox(
                                  width: width,
                                  child: _VideoStory(story: story),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 48),
                    FarmaHeading(
                      'Common questions',
                      style: theme.textTheme.headlineMedium,
                    ),
                    for (final (question, answer) in content.questions)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(question),
                        childrenPadding: const EdgeInsets.only(bottom: 16),
                        expandedAlignment: AlignmentDirectional.centerStart.resolve(
                          Directionality.of(context),
                        ),
                        children: [Text(answer)],
                      ),
                    const SizedBox(height: 48),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Farma by BlumeByte · Accra, Ghana',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final item in const [
                          ('home', 'Home'),
                          ('about', 'About us'),
                          ('profile', 'Profile'),
                          ('projects', 'Projects'),
                          ('services', 'Services'),
                        ])
                          TextButton(
                            onPressed: () => onNavigate(item.$1),
                            child: Text(item.$2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageExample extends StatelessWidget {
  const _PageExample({required this.example});
  final ({String title, List<(String, String)> rows}) example;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FarmaHeading(example.title, style: theme.textTheme.headlineSmall),
            for (final (label, value) in example.rows) ...[
              const Divider(height: 28),
              Text(label, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoStory extends StatefulWidget {
  const _VideoStory({required this.story});

  final FarmaStory story;

  @override
  State<_VideoStory> createState() => _VideoStoryState();
}

class _VideoStoryState extends State<_VideoStory> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;

  Future<void> _start() async {
    if (_loading) return;
    final controller = VideoPlayerController.asset(widget.story.file);
    _controller = controller;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setVolume(0);
      if (!mounted) return;
      await controller.play();
    } catch (_) {
      if (mounted) {
        _controller = null;
        _failed = true;
        await controller.dispose();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;
    final story = widget.story;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: controller != null && controller.value.isInitialized
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoPlayer(controller),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ValueListenableBuilder(
                            valueListenable: controller,
                            builder: (_, value, _) => IconButton.filled(
                              tooltip: value.isPlaying ? 'Pause' : 'Play',
                              onPressed: () async {
                                if (value.isPlaying) {
                                  await controller.pause();
                                } else {
                                  if (value.isCompleted) {
                                    await controller.seekTo(Duration.zero);
                                  }
                                  await controller.play();
                                }
                              },
                              icon: Icon(
                                value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        story.image,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                      Center(
                        child: _loading
                            ? const CircularProgressIndicator()
                            : IconButton.filled(
                                tooltip: 'Play ${story.title}',
                                onPressed: _start,
                                icon: const Icon(Icons.play_arrow, size: 34),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        FarmaHeading(story.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(story.caption),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Read walkthrough steps'),
          children: [
            for (final (index, step) in story.steps.indexed)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${index + 1}. $step'),
                ),
              ),
          ],
        ),
        if (_failed)
          const Text('Could not play the video. Select Play to retry.'),
      ],
    );
  }
}
