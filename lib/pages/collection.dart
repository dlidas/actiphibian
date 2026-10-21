import 'package:actiphibian/services/gacha.dart';
import 'package:flutter/material.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  bool _isGachaVisible = false;

  Future<void> _showPopup() async {
    setState(() {
      _isGachaVisible = true;
    });
    
    await showDialog(context: context, builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.tertiary,        
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                var a = await GachaRoller.roll();
                print(a);
              }, 
              child: const Text('I\'m feeling lucky')
            ),
          ]
        ),
      );
    });

    setState(() {
      _isGachaVisible = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Collection(),
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

class Collection extends StatelessWidget {
  const Collection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(8),
      child: GridView.builder(
        itemCount: 24,
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
                child: AmphibianIcon(gridId: index),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AmphibianIcon extends StatefulWidget {
  final int gridId;
  
  const AmphibianIcon({super.key, required this.gridId});

  @override
  State<AmphibianIcon> createState() => _AmphibianIconState();
}

class _AmphibianIconState extends State<AmphibianIcon> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        print('clicked ${widget.gridId}!');
      }, 
      icon: Image.asset('assets/images/red-eyed-tree-frog.png'),
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

class Gacha extends StatelessWidget {
  const Gacha({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Gacha Placeholder'),
    );
  }
}