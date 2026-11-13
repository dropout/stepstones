enum AdminFlavor {
  dev(usesEmulator: true),
  staging(usesEmulator: false),
  prod(usesEmulator: false);

  const AdminFlavor({required this.usesEmulator});

  final bool usesEmulator;
}
