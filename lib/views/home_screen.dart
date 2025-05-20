import 'package:flutter/material.dart';
import '../models/talk.dart';

class HomePage extends StatelessWidget {
  final Talk? talkToShow;
  const HomePage({super.key, this.talkToShow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My TEDx App')),
      body: Center(
        child: talkToShow == null
            ? const Text('Nessun talk trovato.')
            : SingleChildScrollView(
                child: Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          talkToShow!.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Speaker: ${talkToShow!.speakers}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: talkToShow!.tags.map((tag) => Chip(label: Text(tag))).toList(),
                        ),
                        const SizedBox(height: 12),
                        Text(talkToShow!.description),
                        const SizedBox(height: 12),
                        Text(
                          'Durata: ${talkToShow!.duration} secondi',
                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pubblicato il: ${talkToShow!.publishedAt}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Altri talk correlati: ${talkToShow!.relatedIds.join(", ")}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Apri il link se vuoi
                            // launch(talkToShow!.url); (con url_launcher)
                          },
                          child: const Text('Guarda su TED'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

