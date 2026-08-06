import 'package:flutter/material.dart';
import '../../domain/models/fare_template_item.dart';

/// 7s Mobile App — Fare Templates Notifier
/// Holds owner-defined Voi Town fixed fare templates.
/// Synchronizes price updates made by Rider/Owner into the Passenger app in real-time.
class FareTemplatesNotifier extends ChangeNotifier {
  List<FareTemplateItem> _templates = [
    const FareTemplateItem(
      id: 'voi_cbd_sgr',
      routeTitle: 'Voi Town Center ↔ Voi SGR Station',
      pickupName: 'Voi Town Center / Market',
      pickupAddress: 'Voi Town Center, Kenya',
      destinationName: 'Voi SGR Railway Station',
      destinationAddress: 'Voi SGR Link Road',
      fare: 150.0,
      estimatedDistanceKm: 5.5,
      estimatedTimeMins: 10,
      notes: 'Standard Voi SGR Connection Rate',
    ),
    const FareTemplateItem(
      id: 'voi_cbd_ttu',
      routeTitle: 'Voi Town Center ↔ TTU Main Campus',
      pickupName: 'Voi Town Center / Market',
      pickupAddress: 'Voi Town Center, Kenya',
      destinationName: 'Taita Taveta University (TTU)',
      destinationAddress: 'TTU Main Campus Road, Voi',
      fare: 200.0,
      estimatedDistanceKm: 8.0,
      estimatedTimeMins: 15,
      notes: 'Campus Transport Special',
    ),
    const FareTemplateItem(
      id: 'voi_cbd_hosp',
      routeTitle: 'Voi Town Center ↔ Moi Referral Hospital',
      pickupName: 'Voi Town Center / Market',
      pickupAddress: 'Voi Town Center, Kenya',
      destinationName: 'Moi County Referral Hospital',
      destinationAddress: 'Hospital Road, Voi Town',
      fare: 100.0,
      estimatedDistanceKm: 2.0,
      estimatedTimeMins: 5,
      notes: 'Short Town Express Route',
    ),
    const FareTemplateItem(
      id: 'voi_cbd_lodge',
      routeTitle: 'Voi Town Center ↔ Voi Wildlife Lodge',
      pickupName: 'Voi Town Center / Market',
      pickupAddress: 'Voi Town Center, Kenya',
      destinationName: 'Voi Wildlife Lodge',
      destinationAddress: 'Tsavo East Gate Road, Voi',
      fare: 250.0,
      estimatedDistanceKm: 7.2,
      estimatedTimeMins: 14,
      notes: 'Safari Lodge Access Rate',
    ),
    const FareTemplateItem(
      id: 'voi_cbd_mwatate',
      routeTitle: 'Voi Town Center ↔ Mwatate Junction',
      pickupName: 'Voi Town Center / Market',
      pickupAddress: 'Voi Town Center, Kenya',
      destinationName: 'Mwatate Junction',
      destinationAddress: 'Voi-Taveta Highway',
      fare: 300.0,
      estimatedDistanceKm: 15.0,
      estimatedTimeMins: 20,
      notes: 'Suburban Highway Route',
    ),
  ];

  List<FareTemplateItem> get templates => List.unmodifiable(_templates);

  /// Called by Rider/Owner app when adjusting a fare template's price.
  void updateTemplateFare(String id, double newFare) {
    final index = _templates.indexWhere((t) => t.id == id);
    if (index != -1) {
      _templates[index] = _templates[index].copyWith(fare: newFare);
      notifyListeners();
    }
  }

  /// Reset to default seed templates if needed.
  void setTemplates(List<FareTemplateItem> updatedList) {
    _templates = updatedList;
    notifyListeners();
  }
}
