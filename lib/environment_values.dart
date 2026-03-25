import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FFDevEnvironmentValues {
  static const String currentEnvironment = 'Production';
  static const String environmentValuesPath =
      'assets/environment_values/environment.json';

  static final FFDevEnvironmentValues _instance =
      FFDevEnvironmentValues._internal();

  factory FFDevEnvironmentValues() {
    return _instance;
  }

  FFDevEnvironmentValues._internal();

  Future<void> initialize() async {
    try {
      final String response =
          await rootBundle.loadString(environmentValuesPath);
      final data = await json.decode(response);
      debugPrint('environment values: $data');
    } catch (e) {
      debugPrint('Error loading environment values: $e');
    }
  }
}

const List<Map<String, String>> brandLogos = [
  {"logo": "assets/images/Brands/drfixit.png", "width": "138"},
  {"logo": "assets/images/Brands/pidilite.png", "width": "138"},
  {"logo": "assets/images/Brands/ultratech.png", "width": "138"},
  {"logo": "assets/images/Brands/Kajaria.png", "width": "138"},
  {"logo": "assets/images/Brands/bosch.png", "width": "138"},
  {"logo": "assets/images/Brands/jaquar.png", "width": "138"},

  // {"logo": "images/brands/jsw.webp", "width": "138", "name": "JSW Neosteel"},
  // {"logo": "images/brands/jaquar.webp", "width": "138", "name": "Jaquar"},
  // {
  //   "logo": "images/brands/hindware-seeklogo.webp",
  //   "width": "138",
  //   "name": "Hindware"
  // },
  // {
  //   "logo": "images/brands/grohe-seeklogo.webp",
  //   "width": "138",
  //   "name": "Grohe"
  // },
  // {"logo": "images/brands/kohler-logo.webp", "width": "138", "name": "Kohler"},

  // {
  //   "logo": "images/brands/asian-paints-vector.webp",
  //   "width": "138",
  //   "name": "Asian Paints Ace"
  // },
  // {
  //   "logo": "images/brands/supreme-industries-logo.webp",
  //   "width": "138",
  //   "name": "Supreme"
  // },
  // {"logo": "images/brands/AstralPipes.webp", "width": "138", "name": "Astral"},
  // {
  //   "logo": "images/brands/ashirvad-by-aliaxis.webp",
  //   "width": "138",
  //   "name": "Ashirvad"
  // },
  // {
  //   "logo": "images/brands/sintex-water-tank-logo.webp",
  //   "width": "138",
  //   "name": "Sintex"
  // },
  // {"logo": "images/brands/finolex.webp", "width": "138", "name": "Finolex"},
  // {"logo": "images/brands/polycab.webp", "width": "138", "name": "Polycab"},
  // {"logo": "images/brands/anchor.webp", "width": "138", "name": "ANCHOR"},
  // {"logo": "images/brands/gmswitch.webp", "width": "138", "name": "GM+"},
  // {"logo": "images/brands/roff.webp", "width": "138", "name": "Roff"},
  // {"logo": "images/brands/bathstory.webp", "width": "138", "name": "Bathstory"},
  // {"logo": "images/brands/ultratech.webp", "width": "138", "name": "UltraTech"},
  // {"logo": "images/brands/zuari.webp", "width": "138", "name": "Zuari Cement"},
  // {"logo": "images/brands/lloyds.webp", "width": "138", "name": "Lloyd"},
  // {"logo": "images/brands/havells.webp", "width": "138", "name": "Havells"},
  // {"logo": "images/brands/philips.webp", "width": "138", "name": "Philips"},
  // {"logo": "images/brands/bosch-logo.webp", "width": "138", "name": "Bosch"},
  // {"logo": "images/brands/merino.webp", "width": "138", "name": "Merino"},
  // {
  //   "logo": "images/brands/centuryply.webp",
  //   "width": "138",
  //   "name": "Centuryply"
  // },
  // {"logo": "images/brands/greenply.webp", "width": "138", "name": "GreenPly"},
  // {"logo": "images/brands/luker.webp", "width": "138", "name": "Luker"},
  // {
  //   "logo": "images/brands/wipro-primary-logo-color-rgb.webp",
  //   "width": "138",
  //   "name": "Wipro"
  // },
  // {
  //   "logo": "images/brands/saintgobain.webp",
  //   "width": "138",
  //   "name": "SAINT-GOBAIN"
  // },
  // {
  //   "logo": "images/brands/heritage.webp",
  //   "width": "138",
  //   "name": "Heritage Carpets"
  // },
  // {"logo": "images/brands/welspun.webp", "width": "138", "name": "Welspun"},
  // {
  //   "logo": "images/brands/featherlite.webp",
  //   "width": "138",
  //   "name": "FetherLite"
  // },
  // {
  //   "logo": "images/brands/ebco-logo.webp",
  //   "width": "138",
  //   "name": "Ebco Livsmart"
  // },
  // {"logo": "images/brands/schneider.webp", "width": "138", "name": "Schneider"},
  // {"logo": "images/brands/pidilite.webp", "width": "138", "name": "Pidilite"},
  // {"logo": "images/brands/cera.webp", "width": "138", "name": "CERA"},
  // {"logo": "images/brands/meenakshi.webp", "width": "138", "name": "Meenakshi"},
  // {
  //   "logo": "images/brands/tata-steel-logo.webp",
  //   "width": "138",
  //   "name": "TataSteel"
  // },
  // {"logo": "images/brands/hafele.webp", "width": "138", "name": "Häfele"},
  // {
  //   "logo": "images/brands/house-of-doors.webp",
  //   "width": "138",
  //   "name": "HouseOfDoors"
  // },
  // {"logo": "images/brands/drfixit.webp", "width": "138", "name": "Dr. Fixit"},
  // {"logo": "images/brands/ikea-logo.webp", "width": "138", "name": "Ikea"},
];
