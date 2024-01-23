import 'dart:convert';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = DecryptPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    print('selected: $value');
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}


class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(wordPair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavoritePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.wordPair,
  });

  final WordPair wordPair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); 

    final style = theme.textTheme.displaySmall!.copyWith(
      color: theme.colorScheme.onPrimary,
      // decorationStyle: ,
    );

    return Card(
      color: theme.colorScheme.surfaceTint,  
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          wordPair.asCamelCase,
          style: style,
          semanticsLabel: "${wordPair.first} ${wordPair.second}"
        ),
        
      ),
    );
  }
}

class DecryptPage extends StatefulWidget {
  const DecryptPage({super.key});

  @override
  State<DecryptPage> createState() => _DecryptPageState();
}

class _DecryptPageState extends State<DecryptPage> {
  final _encryptedTextController = TextEditingController();
  final _decryptedTextController = TextEditingController();
  final _encryptionKeyController = TextEditingController();
  String _selectedKeyBit = 'Base64';
  final _ivController = TextEditingController(); // For initialization vector

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AES Decryption'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _encryptedTextController,
                      decoration: const InputDecoration(
                        labelText: 'Encrypted Text',
                      ),
                      maxLines: 5,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: DropdownButton<String>(
                      value: _selectedKeyBit,
                      items: const [
                        DropdownMenuItem(value: 'Base64', child: Text('Base64')),
                        DropdownMenuItem(value: 'Hex', child: Text('Hex')),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          _selectedKeyBit = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _encryptionKeyController,
                decoration: const InputDecoration(
                  labelText: 'Encryption Key',
                ),
              ),
        
              const SizedBox(height: 16),
              TextField(
                controller: _ivController,
                decoration: const InputDecoration(
                  labelText: 'Initialization Vector (IV)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _decryptText,
                child: const Text('Decrypt'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _decryptedTextController,
                decoration: const InputDecoration(
                  labelText: 'Decrypted Text',
                ),
                readOnly: true,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
   void _decryptText() async {
    final encryptedText = _encryptedTextController.text;
    final encryptionKey = _encryptionKeyController.text;
    final ivText = _ivController.text;
    final selectedKeyBit = _selectedKeyBit;
    print(selectedKeyBit);

    try {
      // Trial Data
      // const String encryptedTextBase64 = "G8hLaH0JuQz5eNaYfx9/VA=="; // decrypted equals Amanuel
      // const String keyBase64 = "YXNkZmFzZGZhc2RmYXNkZg=="; // asdfasdfasdfasdf
      // const String ivBase64 = "YXNkZmFzZGZhc2RmYXNkZg==";f

      final keyBase64 = base64Url.encode(utf8.encode(encryptionKey));
      final ivBase64 = base64Url.encode(utf8.encode(ivText));

      final key = encrypt.Key.fromBase64(keyBase64);
      final iv = encrypt.IV.fromBase64(ivBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key,  mode: encrypt.AESMode.cbc));
      final decryptedText = encrypter.decrypt64(encryptedText, iv: iv);

      print("Decrypted Text: $decryptedText");
      _decryptedTextController.text = decryptedText;

    } catch (error) {
      _decryptedTextController.text = 'Error during decryption: $error';
      print(_decryptedTextController.text);
    }
  }
}