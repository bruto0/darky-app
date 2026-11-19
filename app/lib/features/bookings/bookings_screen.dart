import 'package:material_ui/material_ui.dart';

import '../../app/shell.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      eyebrow: 'Расписание',
      title: 'Записи',
      subtitle: 'Предстоящие записи, QR и отмена — после спайка API.',
      icon: Icons.event_outlined,
    );
  }
}
