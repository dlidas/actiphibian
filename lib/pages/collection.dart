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

  Future<void> _showPopup() async {
    setState(() {
      _isGachaVisible = true;
      _refreshCounter++;
    });
    
    await showDialog(context: context, builder: (BuildContext context) {
      return StatefulBuilder(builder: (context, setDialogueState) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.tertiary,        
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                margin: EdgeInsets.all(15),
                child: Padding(
                  padding: EdgeInsetsGeometry.all(20),
                  child: (path == null) ? Icon(Icons.question_mark) : Image.asset('assets/images/${path!}'),
                  // child: Icon(Icons.question_mark),
                ),
              ),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: 20),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Theme.of(context).colorScheme.secondary;
                      }
                      return Theme.of(context).colorScheme.primary;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Theme.of(context).colorScheme.onSecondary;
                      }
                      return Theme.of(context).colorScheme.onPrimary;
                    }),
                  ),
                  onPressed: () async {
                    var a = await GachaRoller.roll();

                    LocalDb.addAmphibian(a);
                    
                    setDialogueState(() {
                      path = a.filePath;
                    });
                  }, 
                  child: const Text('I\'m feeling lucky')
                ),
              )
            ]
          ),
        );
      });
    });

    setState(() {
      _isGachaVisible = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Collection(key: ValueKey(_refreshCounter),),
        floatingActionButton: _isGachaVisible ? null : FloatingActionButton.large(
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
    collection  = LocalDb.getAmphibians(); //HERE!!!    
  }

  Future<void> _reload() async {
    setState(() {
      collection = LocalDb.getAmphibians();      
    });
    print((await collection).toString());
    await collection; // lets RefreshIndicator know when to stop spinning
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(8),
      child: FutureBuilder(
        future: collection, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Nothing here but flies!'),);
          }

          final actualCollection = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _reload, 
            child: GridView.builder(
              itemCount: actualCollection.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsetsGeometry.all(5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AmphibianIcon(amphibian: actualCollection[index],),
                    ),
                  ),
                );
              },
            ),
          );
        }
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
    return Center(
      child: Text('Info Placeholder'),
    );
  }
}