class VehicleData {
  static const Map<String, List<String>> brandModels = {
    'TOYOTA': [
      'AGYA',
      'ALLEX',
      'ALLION',
      'ALPHARD',
      'ALTEZZA',
      'AQUA',
      'AURIS',
      'AVENSIS',
      'BB',
      'BELTA',
      'BLADE',
      'CALDINA',
      'CAMRY',
      'CARINA',
      'CELICA',
      'CHASER',
      'COROLLA',
      'CROWN',
      'DYNA',
      'ESTIMA',
      'FJ CRUISER',
      'FORTUNER',
      'HARRIER',
      'HIACE',
      'HILUX',
      'IPSUM',
      'ISIS',
      'LAND CRUISER',
      'MARK II',
      'NOAH',
      'PASSO',
      'PREMIO',
      'PRIUS',
      'PROBOX',
      'RAV4',
      'RUSH',
      'SIENTA',
      'SUCCEED',
      'VANGUARD',
      'VITZ',
      'WISH',
      'YARIS'
    ],
    'NISSAN': [
      'ATLAS',
      'BLUEBIRD',
      'CARAVAN',
      'CIVILIAN',
      'CUBE',
      'DUALIS',
      'ELGRAND',
      'FAIRLADY Z',
      'FUGA',
      'JUKE',
      'LAFESTA',
      'MARCH',
      'MURANO',
      'NAVARA',
      'NOTE',
      'PATROL',
      'PRIMERA',
      'SERENA',
      'SKYLINE',
      'TEANA',
      'TIIDA',
      'X-TRAIL'
    ],
    'HONDA': [
      'ACCORD',
      'AIRWAVE',
      'CIVIC',
      'CR-V',
      'CROSSROAD',
      'FIT',
      'FREED',
      'HR-V',
      'INSIGHT',
      'INTEGRA',
      'JAZZ',
      'LEGEND',
      'ODYSSEY',
      'STREAM'
    ],
    'MAZDA': [
      'ATENZA',
      'AXELA',
      'BONGO',
      'CAPELLA',
      'CX-5',
      'DEMIO',
      'FAMILIA',
      'MPV',
      'PREMACY',
      'RX-8',
      'TRIBUTE'
    ],
    'MITSUBISHI': [
      'CANTER',
      'CHALLENGER',
      'DELICA',
      'ECLIPSE',
      'GALANT',
      'L200',
      'LANCER',
      'OUTLANDER',
      'PAJERO',
      'RVR',
      'TRITON'
    ]
  };

  static List<String> get allBrands => brandModels.keys.toList();

  static List<String> getModelsForBrand(String brand) {
    final key = brand.toUpperCase();
    return brandModels[key] ?? [];
  }

  static bool isValidBrandModel(String brand, String model) {
    final models = getModelsForBrand(brand);
    return models.contains(model.toUpperCase());
  }

  static List<String> searchModels(String query) {
    query = query.toUpperCase();
    List<String> results = [];

    for (var entry in brandModels.entries) {
      for (var model in entry.value) {
        if (model.contains(query)) {
          results.add('${entry.key} $model');
        }
      }
    }

    return results;
  }
}
