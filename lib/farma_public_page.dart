import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

typedef FarmaSection = ({IconData icon, String title, String body});
typedef FarmaStory = ({
  String title,
  String caption,
  String file,
  String image,
});

class FarmaPageContent {
  const FarmaPageContent({
    required this.heading,
    required this.intro,
    required this.image,
    required this.imageDescription,
    required this.sectionHeading,
    required this.sections,
    this.stories = const [],
  });

  final String heading;
  final String intro;
  final String image;
  final String imageDescription;
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
);

const _marketStory = (
  title: 'Preparing a produce listing',
  caption: 'A short walkthrough of how farmers can start recording details for a future listing.',
  file: 'assets/farma/produce-walkthrough.mp4',
  image: _produceImage,
);

const farmaPages = {
  'home': FarmaPageContent(
    heading: 'Keep track of what happens in the field.',
    intro: 'Farma is BlumeByte’s agricultural workspace for farmers, field teams and produce buyers. Start with a photo and a note, then build a history of what you observe and what you plan to sell.',
    image: _fieldImage,
    imageDescription: _fieldPhoto,
    sectionHeading: 'From the field to the market',
    sections: [
      (
        icon: Icons.photo_camera_outlined,
        title: 'Capture field observations',
        body: 'Save dated photos, categories and notes as you visit your farm. Reopen them when you inspect the same crop or prepare for a conversation with a field officer.',
      ),
      (
        icon: Icons.storefront_outlined,
        title: 'Prepare produce listings',
        body: 'Create a draft for what you have harvested. Record the produce name and add a representative photo and notes before preparing it for buyers.',
      ),
      (
        icon: Icons.public_outlined,
        title: 'Sign up from anywhere',
        body: 'Choose your country or territory and calling code. Farma’s account screens are available in nine languages and follow your device’s light or dark appearance.',
      ),
    ],
    stories: [_fieldStory, _marketStory],
  ),
  'about': FarmaPageContent(
    heading: 'About us',
    intro: 'Farma began in Accra, Ghana, with a practical question. How can a farmer keep useful records in the field and prepare clearer information for a buyer or an extension worker?',
    image: _fieldImage,
    imageDescription: _fieldPhoto,
    sectionHeading: 'What we are building',
    sections: [
      (
        icon: Icons.grass_outlined,
        title: 'Practical field records',
        body: 'A farmer can record an observation using a photo, a short note and a category. Saved records can be reopened on the same device after the app has loaded.',
      ),
      (
        icon: Icons.wifi_off_outlined,
        title: 'Designed around low connectivity',
        body: 'The project brief prioritizes workflows that remain useful when internet access is limited. On-device guidance, synchronization and broader offline support are planned areas of work.',
      ),
      (
        icon: Icons.people_outline,
        title: 'Built with distinct roles in mind',
        body: 'The design calls for a farmer workspace for field observations and a buyer workspace for discovering and comparing produce. The current public trial includes observation records and produce drafts.',
      ),
    ],
    stories: [_fieldStory],
  ),
  'profile': FarmaPageContent(
    heading: 'Profile',
    intro: 'Farma is a BlumeByte Digital Solution project based in Accra, Ghana. The project brings together field documentation, agricultural services and farm-to-buyer commerce.',
    image: _fieldImage,
    imageDescription: _fieldPhoto,
    sectionHeading: 'Project profile',
    sections: [
      (
        icon: Icons.location_on_outlined,
        title: 'Ghana-rooted, built for wider use',
        body: 'The partner brief takes Ghana’s farming and district context as its starting point. The signup form supports international country and territory codes so users can register with a number from their own region.',
      ),
      (
        icon: Icons.person_outline,
        title: 'Who Farma is for',
        body: 'Farmers can document an observation or start a produce draft. Field teams can use those records as a starting point for follow-up. Buyer discovery and direct communication are part of the planned marketplace.',
      ),
      (
        icon: Icons.security_outlined,
        title: 'How accounts and records work',
        body: 'Farma uses email and password for account access. Signup details are handled through Supabase. Field photos, notes and drafts in the current trial are stored per account on the device.',
      ),
    ],
    stories: [_fieldStory],
  ),
  'projects': FarmaPageContent(
    heading: 'Projects',
    intro: 'Explore the field workspace, marketplace and district pilot concept behind Farma. Features in the current trial are identified alongside work described in the project brief.',
    image: _produceImage,
    imageDescription: _producePhoto,
    sectionHeading: 'Product and pilot work',
    sections: [
      (
        icon: Icons.edit_note_outlined,
        title: 'Field workspace · Available',
        body: 'Create photo observations, organize them by category and keep notes on what changed. Saved records are available on the same device.',
      ),
      (
        icon: Icons.storefront_outlined,
        title: 'Produce showcase · Drafts available',
        body: 'Save a produce draft with a name, photo and notes. Published listings, short produce videos and one-to-one buyer messaging are planned in the marketplace design.',
      ),
      (
        icon: Icons.map_outlined,
        title: 'District pilot · Planned',
        body: 'The partnership brief outlines a potential district-level pilot for training, field workflows and review. Proposed field reporting and mapping features depend on partner participation and validation.',
      ),
      (
        icon: Icons.record_voice_over_outlined,
        title: 'Accessible guidance · Planned',
        body: 'The design brief proposes short visual guides and audio in English, Twi, Ga, Ewe, Dagbani and Hausa. Those guides are distinct from the translated signup screens available today.',
      ),
    ],
    stories: [_fieldStory, _marketStory],
  ),
  'services': FarmaPageContent(
    heading: 'Services',
    intro: 'Use the Farma workspace to document field observations and prepare produce records. Keep a record for follow-up and review your drafts before sharing produce information.',
    image: _produceImage,
    imageDescription: _producePhoto,
    sectionHeading: 'What you can do in the trial',
    sections: [
      (
        icon: Icons.camera_alt_outlined,
        title: 'Record an observation',
        body: 'Open Observations, add a photo or choose an existing image, then add a category, title and notes. Save it and revisit it whenever you need the record.',
      ),
      (
        icon: Icons.inventory_2_outlined,
        title: 'Create a produce draft',
        body: 'Open Produce, enter the name of the crop or item and attach a photo. Add useful notes about the harvest or condition. Review those details before preparing a public listing.',
      ),
      (
        icon: Icons.language_outlined,
        title: 'Set up your account',
        body: 'Choose a language on the sign-in screen. At signup, supply a unique username, email and an international phone number. The public pages are available before you sign in.',
      ),
    ],
    stories: [_marketStory],
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
        final image = AspectRatio(
          aspectRatio: wide ? 1.2 : 1.55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              content.image,
              fit: BoxFit.cover,
              semanticLabel: content.imageDescription,
            ),
          ),
        );
        final lead = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content.heading,
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
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: onSignIn,
                  child: const Text('Sign in to your workspace'),
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
                    Text(
                      content.sectionHeading,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, layout) {
                        final columns = wide ? 2 : 1;
                        final width =
                            (layout.maxWidth - (columns - 1) * 16) / columns;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final section in content.sections)
                              SizedBox(
                                width: width,
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(section.icon, size: 28),
                                        const SizedBox(height: 14),
                                        Text(
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
                              ),
                          ],
                        );
                      },
                    ),
                    if (content.stories.isNotEmpty) ...[
                      const SizedBox(height: 50),
                      Text(
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
        Text(story.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(story.caption),
        if (_failed)
          const Text('Could not play the video. Select Play to retry.'),
      ],
    );
  }
}
