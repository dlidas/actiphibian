import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/models/amphibian.dart';
import 'package:actiphibian/services/gacha.dart';
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

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogueState) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'A new pond friend',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(24),
                      child: path == null
                          ? const Icon(Icons.question_mark, size: 48)
                          : Image.asset(
                              'assets/images/$path',
                              width: 64,
                              height: 64,
                            ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        setDialogueState(() => _rollError = null);
                        try {
                          final amphibian = await GachaRoller.roll();

                          await LocalDb.addAmphibian(amphibian);
                          if (mounted) {
                            setState(() => _refreshCounter++);
                          }
                          if (!context.mounted) return;

                          setDialogueState(() {
                            path = amphibian.filePath;
                          });
                        } catch (error, stackTrace) {
                          debugPrint('Could not roll for an amphibian: $error');
                          debugPrintStack(stackTrace: stackTrace);
                          if (!context.mounted) return;
                          setDialogueState(() {
                            _rollError =
                                'Could not add a pond friend. Try again.';
                          });
                        }
                      },
                      child: const Text("I'm feeling lucky"),
                    ),
                    if (_rollError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _rollError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) setState(() => _isGachaVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Collection(key: ValueKey(_refreshCounter)),
        floatingActionButton: _isGachaVisible
            ? null
            : FloatingActionButton.large(
                onPressed: () {
                  //Gacha
                  _showPopup();
                },
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
    collection = LocalDb.getAmphibians(); //HERE!!!
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
      child: FutureBuilder(
        future: collection,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Your collection could not be loaded.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _reload,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Icon(Icons.pets_outlined, size: 48),
                SizedBox(height: 12),
                Center(child: Text('Your pond friends will appear here.')),
              ],
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
                return Card(
                  color: Theme.of(context).colorScheme.secondary,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
    return Center(child: Text('Info Placeholder'));
  }
}
