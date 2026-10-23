import 'package:actiphibian/data/userManager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserStatsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  const UserStatsAppBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserManager>().user;
    final colors = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();
    final coinIndicator = Tooltip(
      message: 'Coins: ${user.balance}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on),
            const SizedBox(width: 4),
            Text(
              '${user.balance}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    return AppBar(
      backgroundColor: colors.primary,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      leadingWidth: canPop ? null : 92,
      leading: canPop
          ? IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : coinIndicator,
      actions: [
        if (canPop) coinIndicator,
        Tooltip(
          message: 'Level ${user.level}',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt),
                const SizedBox(width: 4),
                Text(
                  '${user.level}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        ...actions,
      ],
    );
  }
}
