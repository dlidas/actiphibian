import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/models/amphibian.dart';
import 'package:actiphibian/services/gacha.dart';
import 'package:actiphibian/widgets/pond_message_state.dart';
import 'package:flutter/material.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  bool _isGachaVisible = false;
  int _refreshCounter = 0;
  String? path;
  String? _rollError;

  Future<void> _showPopup() async {
    setState(() {
      _isGachaVisible = true;
      _refreshCounter++;
      _rollError = null;
    });

    await showDialog(context: context, builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setDialogueState) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.all(15),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: path == null
                      ? const Icon(Icons.question_mark)
                      : Image.asset(
                          'assets/images/${path!}',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: () async {
                    setDialogueState(() => _rollError = null);
                    try {
                      final amphibian = await GachaRoller.roll();
                      await LocalDb.addAmphibian(amphibian);
                      if (mounted) setState(() => _refreshCounter++);
                      if (!context.mounted) return;
                      setDialogueState(() => path = amphibian.filePath);
                    } catch (error, stackTrace) {
                      debugPrint('Could not roll for an amphibian: $error');
                      debugPrintStack(stackTrace: stackTrace);
                      if (context.mounted) {
                        setDialogueState(() {
                          _rollError = 'Could not add a pond friend. Try again.';
                        });
                      }
                    }
                  },
                  child: const Text('I\'m feeling lucky'),
                ),
              ),
              if (_rollError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _rollError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        );
      });
    });

    if (mounted) setState(() => _isGachaVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Collection(key: ValueKey(_refreshCounter)),
        floatingActionButton: _isGachaVisible ? null : FloatingActionButton.large(
          onPressed: _showPopup,
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          foregroundColor: Theme.of(context).colorScheme.onTertiary,
          shape: const CircleBorder(),
          tooltip: 'Roll for a new Amphibian',
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class Collection extends StatefulWidget {
  const Collection({super.key});

  @override
  State<Collection> createState() => _CollectionState();
}

class _CollectionState extends State<Collection> {
  late Future<List<Amphibian>> collection;

  @override
  void initState() {
    super.initState();
    collection = LocalDb.getAmphibians();
  }

  Future<void> _reload() async {
    setState(() {
      collection = LocalDb.getAmphibians();
    });
    await collection;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: FutureBuilder<List<Amphibian>>(
        future: collection,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return PondMessageState(
              icon: Icons.cloud_off_outlined,
              message: 'Your collection could not be loaded.',
              action: TextButton(
                onPressed: _reload,
                child: const Text('Try again'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  PondMessageState(
                    icon: Icons.pets_outlined,
                    message: 'Your pond friends will appear here.',
                  ),
                ],
              ),
            );
          }

          final actualCollection = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: GridView.builder(
              itemCount: actualCollection.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(5),
                  child: Card(
                    color: Theme.of(context).colorScheme.secondary,
                    child: AmphibianIcon(amphibian: actualCollection[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AmphibianIcon extends StatefulWidget {
  final Amphibian amphibian;

  const AmphibianIcon({super.key, required this.amphibian});

  @override
  State<AmphibianIcon> createState() => _AmphibianIconState();
}

class _AmphibianIconState extends State<AmphibianIcon> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        //TODO: Show Information
      },
      icon: Image.asset('assets/images/${widget.amphibian.filePath}'),
    );
  }
}

class AmphibianInfo extends StatelessWidget {
  const AmphibianInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Info Placeholder'));
  }
}
