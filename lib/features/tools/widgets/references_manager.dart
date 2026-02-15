import 'package:flutter/material.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../director_ref/widgets/director_ref_manager.dart';
import '../../vibe_transfer/widgets/vibe_transfer_manager.dart';

class ReferencesManager extends StatefulWidget {
  const ReferencesManager({super.key});

  @override
  State<ReferencesManager> createState() => _ReferencesManagerState();
}

class _ReferencesManagerState extends State<ReferencesManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final l = context.l;
    return Column(
      children: [
        Container(
          color: t.surfaceMid,
          child: TabBar(
            controller: _tabController,
            indicatorColor: t.accent,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textDisabled,
            labelStyle: TextStyle(
              fontSize: t.fontSize(9),
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: t.fontSize(9),
              fontWeight: FontWeight.normal,
              letterSpacing: 2,
            ),
            tabs: [
              Tab(text: l.refPreciseReferences),
              Tab(text: l.refVibeTransfer),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              DirectorRefManager(),
              VibeTransferManager(),
            ],
          ),
        ),
      ],
    );
  }
}
