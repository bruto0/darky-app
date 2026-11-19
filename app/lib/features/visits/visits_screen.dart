import 'package:material_ui/material_ui.dart';

import '../../app/shell.dart';

class VisitsScreen extends StatelessWidget {
  const VisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      eyebrow: 'История',
      title: 'Посещения',
      subtitle: 'Список визитов с датой, занятием, залом и преподавателем.',
      icon: Icons.directions_walk_outlined,
    );
  }
}
