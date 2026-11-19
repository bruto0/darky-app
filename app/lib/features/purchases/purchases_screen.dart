import 'package:material_ui/material_ui.dart';

import '../../app/shell.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      eyebrow: 'История',
      title: 'Покупки',
      subtitle: 'Пополнения и списания по абонементам, без оплаты в приложении.',
      icon: Icons.shopping_bag_outlined,
    );
  }
}
