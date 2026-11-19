import 'package:material_ui/material_ui.dart';

import '../../core/ui/theme.dart';
import 'schedule_fab.dart';
import 'schedule_section.dart';

/// Focused test/demo scaffold: one `CustomScrollView` with the schedule
/// slivers and the floating refresh button. In production the parent embeds
/// [ScheduleSection] and [ScheduleFab] into the home screen instead.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const ScheduleSection(bottomPadding: 96),
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
              ),
            ],
          ),
          const Positioned.fill(child: ScheduleFab()),
        ],
      ),
    );
  }
}
