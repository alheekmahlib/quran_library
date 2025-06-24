/// A model class representing a Sajda (prostration) in the Quran.
/// This class is used to store information about recommended and obligatory prostrations.
class SajdaFontsModel {
  /// The unique identifier for the Sajda.
  final int id;
  
  /// Indicates whether this Sajda is recommended.
  final bool recommended;
  
  /// Indicates whether this Sajda is obligatory.
  final bool obligatory;

  /// Creates a new SajdaFontsModel instance.
  SajdaFontsModel({
    required this.id, 
    required this.recommended, 
    required this.obligatory
  });

  /// Creates a SajdaFontsModel from a JSON map.
  factory SajdaFontsModel.fromJson(Map<String, dynamic> json) {
    return SajdaFontsModel(
      id: json['id'],
      recommended: json['recommended'] ?? false,
      obligatory: json['obligatory'] ?? false, // Assuming obligatory might not always be present
    );
  }
}