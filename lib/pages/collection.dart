import 'package:actiphibian/data/repo.dart';
import 'package:actiphibian/data/user_manager.dart';
import 'package:actiphibian/models/amphibian.dart';
import 'package:actiphibian/models/user.dart';
import 'package:actiphibian/services/gacha.dart';
import 'package:actiphibian/services/sound_player.dart';
import 'package:actiphibian/widgets/pond_message_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  bool _isGachaVisible = false;
  int _refreshCounter = 0;
  Amphibian? amphibian;
  String? _rollError;
  late int currency;
  //Map Rarities to colors for UI
  final Map<Rarity, Color> rarityColorMap = {
    Rarity.common: Colors.grey,
    Rarity.uncommon: Colors.lightGreen,
    Rarity.rare: Colors.lightBlue,
    Rarity.legendary: Colors.yellow
  };

  //Show Gacha draw window
  Future<void> _showPopup() async {
    setState(() {
      _isGachaVisible = true;
      _refreshCounter++;
      _rollError = null;
      currency = Provider.of<UserManager>(context, listen: false).user.balance;
    });

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogueState) {
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
                          padding: EdgeInsetsGeometry.all(20),
                          child: (amphibian == null)
                          ? const Icon(Icons.question_mark)
                          : Image.asset(
                              'assets/images/${amphibian!.filePath}',
                              width: 64,
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                        ),                    
                  ),
                  Column(
                      children: [                        
                        Container(
                          padding: EdgeInsets.all(10),
                          child: (amphibian == null) 
                            ? Text('???')
                            : Column(//Amphibian info
                              children: [                                
                                Container(//Rarity
                                  decoration: BoxDecoration(
                                    color: rarityColorMap[amphibian!.rarity],
                                  ),
                                  padding: EdgeInsets.all(5),
                                  child: Text(amphibian!.rarity.name.toUpperCase()),
                                ),
                                Text(//Amphibian name
                                  amphibian!.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                  )),
                              ],
                            ),
                        ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: (currency >= 50) ? ElevatedButton(//Roll button
                      onPressed: () async {
                        SoundPlayer.playSound('audio/congratulations.mp3');
                        setDialogueState(() => _rollError = null);
                        try {
                          //roll for random Amphibian
                          final amphibianRolled = await GachaRoller.roll();
                          await LocalDb.addAmphibian(amphibianRolled);
                          if (mounted) setState(() => _refreshCounter++);
                          //Refresh
                          if (!context.mounted) return;
                          setDialogueState(() => amphibian = amphibianRolled);
                        } catch (error, stackTrace) {
                          debugPrint('Could not roll for an amphibian: $error');
                          debugPrintStack(stackTrace: stackTrace);
                          if (context.mounted) {
                            setDialogueState(() {
                              _rollError =
                                  'Could not add a pond friend. Try again.';
                            });
                          }
                        }
                        //Update currency
                        User user = Provider.of<UserManager>(context, listen: false).user;
                        user.balance -= 50;
                        LocalDb.updateUser(user);
                        context.read<UserManager>().updateUser(user);
                      },
                      child: (amphibian == null) ? const Text('Roll for a new amphibian (50 coins)'):
                        const Text('Roll again! (50 coins)'),
                    ): Column(//Insufficient Funds button
                      children: [
                        ElevatedButton(
                          onPressed: null, 
                          child: const Text('Not enough coins (50 needed)'),
                        ),
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 25, vertical: 10),
                          child: Center(
                            child: Text('Complete tasks or focus sessions to earn currency.'),
                          ),
                        )
                      ],
                    ),
                  ),
                  if (_rollError != null)
                    Padding(//Error message
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _rollError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      setDialogueState(() => amphibian = null);
                      Navigator.pop(context);
                    }, 
                    child: const Text('Back')
                  ),
                ],
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
            : FloatingActionButton.large(//Open Gacha menu
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
                children: [
                  const SizedBox(height: 100),
                  PondMessageState(
                    icon: Icons.pets_outlined,
                    illustration: Image.asset(
                      'assets/images/placeholder-frog-icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                    message: 'Your pond friends will appear here.',
                  ),
                ],
              ),
            );
          }

          final actualCollection = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: GridView.builder(//Gallery of Amphibians
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
  bool _isInfoVisible = false;
  int _refreshCounter = 0;
  //Map Rarities to colors for UI
  final Map<Rarity, Color> rarityColorMap = {
    Rarity.common: Colors.grey,
    Rarity.uncommon: Colors.lightGreen,
    Rarity.rare: Colors.lightBlue,
    Rarity.legendary: Colors.yellow
  };

  //Show Amphibian info window
  Future<void> _showInfo() async {
    setState(() {
      _isInfoVisible = true;
      _refreshCounter++;
    });

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogueState) {
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
                          padding: EdgeInsetsGeometry.all(20),
                          child: Image.asset(
                              'assets/images/${widget.amphibian.filePath}',
                              width: 64,
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                        ),                    
                  ),
                  Column(
                      children: [                        
                        Container(
                          padding: EdgeInsets.all(10),
                          child: Column(//Amphibian info
                              children: [                                
                                Container(//Rarity
                                  decoration: BoxDecoration(
                                    color: rarityColorMap[widget.amphibian.rarity],
                                  ),
                                  padding: EdgeInsets.all(5),
                                  child: Text(widget.amphibian.rarity.name.toUpperCase()),
                                ),
                                Text(//Amphibian name
                                  widget.amphibian.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                                //Long descriptions scroll inside the dialog
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height * 0.4,
                                  ),
                                  child: SingleChildScrollView(
                                    padding: EdgeInsetsGeometry.all(15),
                                    child: Text(
                                      widget.amphibian.description,
                                      textAlign: TextAlign.justify,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ),
                      ],
                    ),                  
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    }, 
                    child: const Text('Back')
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (mounted) setState(() => _isInfoVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _showInfo,
      //Names the amphibian for screen readers and on long press
      tooltip: widget.amphibian.name,
      icon: Image.asset(
        'assets/images/${widget.amphibian.filePath}',
        semanticLabel: widget.amphibian.name,
      ),
    );
  }
}
