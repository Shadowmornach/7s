import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/passenger_provider.dart';

class DestinationSearchScreen extends StatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PassengerNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Destination'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Where to? (e.g. Westlands)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.searchPlacesDebounced('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) => provider.searchPlacesDebounced(val),
              ),
            ),
            if (provider.isSearching) const LinearProgressIndicator(),
            if (provider.searchError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  provider.searchError!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.searchResults.length,
                itemBuilder: (context, index) {
                  final place = provider.searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(place.primaryText, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(place.secondaryText),
                    onTap: () async {
                      await provider.selectDestination(place);
                      if (context.mounted) {
                        context.pop();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
