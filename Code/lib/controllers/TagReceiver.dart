// lib/services/tag_service.dart

import 'package:amplify_flutter/amplify_flutter.dart';

class TagReceiver {
  /// Recupera l’attributo custom:tags da Cognito e restituisce
  /// una List<String> di tag puliti (senza “#”).
  static Future<List<String>> fetchAvailableTags() async {
    try {
      // 1. Prendi tutti gli attributi utente da Cognito
      final attrs = await Amplify.Auth.fetchUserAttributes();

      // 2. Trova l’attributo custom:tags (si assume non vuoto)
      final rawTagAttr = attrs.firstWhere(
        (a) => a.userAttributeKey == const CognitoUserAttributeKey.custom('tags'),
        orElse: () => throw Exception('Attributo custom:tags non trovato'),
      ).value;

      // 3. Splitta e pulisci ogni tag rimuovendo “#” e spazi superflui
      final List<String> availableTags = rawTagAttr
          .split(',')
          .map((t) => t.trim().replaceFirst('#', ''))
          .toList();

      return availableTags;
    } on AuthException catch (e) {
      throw Exception('Errore fetchUserAttributes: ${e.message}');
    } catch (e) {
      throw Exception('Errore recupero tags: $e');
    }
  }
}
