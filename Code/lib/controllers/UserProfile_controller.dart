// lib/controllers/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/DataCache.dart';

/// Modello: rappresenta i campi utente e sa parsare/serializzare le preferenze
class UserProfile {
  String nickname;
  String name;
  String birthdate;
  String email;
  String address;
  String gender;
  int preferencesMask;

  UserProfile({
    required this.nickname,
    required this.name,
    required this.birthdate,
    required this.email,
    required this.address,
    required this.gender,
    required this.preferencesMask,
  });

  factory UserProfile.fromAttributes(List<AuthUserAttribute> attrs) {
    final map = { for (var a in attrs) a.userAttributeKey.key: a.value };
    return UserProfile(
      nickname:      map['nickname']        ?? '',
      name:          map['name']            ?? '',
      birthdate:     map['birthdate']       ?? '',
      email:         map['email']           ?? '',
      address:       map['address']         ?? '',
      gender:        map['gender']          ?? '',
      preferencesMask: int.tryParse(map['custom:preferences'] ?? '') ?? 0,
    );
  }

  List<Future<UpdateUserAttributeResult>> toUpdateOperations() {
    return [
      Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.nickname,
        value: nickname,
      ),
      Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.name,
        value: name,
      ),
      Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.birthdate,
        value: birthdate,
      ),
      Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.email,
        value: email,
      ),
      Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.address,
        value: address,
      ),
      Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.gender,
        value: gender,
      ),
      Amplify.Auth.updateUserAttribute(
        userAttributeKey:
            const CognitoUserAttributeKey.custom('preferences'),
        value: preferencesMask.toString(),
      ),
    ];
  }

  Map<String,bool> extractPreferences(List<String> keys) {
    final result = <String,bool>{};
    for (var i = 0; i < keys.length; i++) {
      result[keys[i]] = ((preferencesMask >> i) & 1) == 1;
    }
    return result;
  }
}

/// Controller: tiene i TextEditingController, la mappa preferenze e la logica di load/save/logout
class ProfileController {
  // TextEditingController per ciascun campo
  final nicknameCtl    = TextEditingController();
  final nameCtl        = TextEditingController();
  final birthdateCtl   = TextEditingController();
  final emailCtl       = TextEditingController();
  final addressCtl     = TextEditingController();
  final cityCtl        = TextEditingController();
  final capCtl         = TextEditingController();
  final genderCtl      = TextEditingController();
  final cittaCtl       = TextEditingController();
  final segniCtl       = TextEditingController();

  // Chiavi delle preferenze
  static const prefsKeys = [
    'Motori','Sport','Politica','Politica estera',
    'Mondo','Animali','Cultura','Finanza',
    'Cronaca nera','Altro...',
  ];
  Map<String,bool> preferences = { for (var k in prefsKeys) k: false };

  UserProfile? profile;
  bool isLoading = false;
  String? error;

  int _computeMask() {
    var m = 0;
    for (var i = 0; i < prefsKeys.length; i++) {
      if (preferences[prefsKeys[i]] == true) {
        m |= 1 << i;
      }
    }
    return m;
  }

  Future<void> loadProfile({ required VoidCallback onDone }) async {
    isLoading = true;
    try {
      final attrs = await Amplify.Auth.fetchUserAttributes();
      profile = UserProfile.fromAttributes(attrs);

      // popola i controller coi valori
      nicknameCtl.text  = profile!.nickname;
      nameCtl.text      = profile!.name;
      birthdateCtl.text = profile!.birthdate;
      emailCtl.text     = profile!.email;
      addressCtl.text   = profile!.address;
      // city e cap erano custom fields? se li usi, popola qui:
      cityCtl.text      = ''; 
      capCtl.text       = '';
      genderCtl.text    = profile!.gender;
      cittaCtl.text     = '';
      segniCtl.text     = '';

      preferences = profile!.extractPreferences(prefsKeys);
      error = null;
    } on AuthException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      onDone();
    }
  }

  Future<void> saveProfile({ required VoidCallback onDone }) async {
    if (profile == null) return;
    isLoading = true;
    try {
      // aggiorna il modello dai controller
      profile!
        ..nickname = nicknameCtl.text.trim()
        ..name     = nameCtl.text.trim()
        ..birthdate= birthdateCtl.text.trim()
        ..email    = emailCtl.text.trim()
        ..address  = addressCtl.text.trim()
        ..gender   = genderCtl.text.trim()
        ..preferencesMask = _computeMask();

      final ops = profile!.toUpdateOperations();
      await Future.wait(ops);

      error = null;
    } on AuthException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      onDone();
    }
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut(options: const SignOutOptions(globalSignOut: true));
      DataCache().clear();
      profile = null;
      preferences = { for (var k in prefsKeys) k: false };
      error = null;
    } on AuthException catch (e) {
      error = e.message;
    }
  }

  void dispose() {
    nicknameCtl.dispose();
    nameCtl.dispose();
    birthdateCtl.dispose();
    emailCtl.dispose();
    addressCtl.dispose();
    cityCtl.dispose();
    capCtl.dispose();
    genderCtl.dispose();
    cittaCtl.dispose();
    segniCtl.dispose();
  }
}
