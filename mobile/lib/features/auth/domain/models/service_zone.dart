/// 7s Domain Engine — ServiceZone Model
class ServiceZone {
  final String code;
  final String name;
  final bool isEnabled;

  const ServiceZone({
    required this.code,
    required this.name,
    this.isEnabled = true,
  });

  static const ServiceZone voi = ServiceZone(
    code: 'VOI',
    name: 'Voi Town',
    isEnabled: true,
  );

  static const List<ServiceZone> supportedZones = [voi];

  static bool isSupportedCode(String code) {
    return code.toUpperCase() == 'VOI';
  }

  @override
  String toString() => name;
}
