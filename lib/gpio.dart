library dslink.rpi.gpio;

import "dart:async";

abstract class GPIO {
  Future init();

  Future<PinMode> getMode(int pin);
  Future setMode(int pin, PinMode mode);

  Future setState(int pin, int value);

  Future<int> getState(int pin);

  Stream<int> watchState(int pin);

  Future startSoftTone(int pin);
  Future stopSoftTone(int pin);
  Future writeSoftTone(int pin, int frequency);
  Future<bool> isSoftTone(int pin);

  Future<String> describe(int pin);
}

class PinMode {
  static const PinMode INPUT = const PinMode._("INPUT");
  static const PinMode OUTPUT = const PinMode._("OUTPUT");

  final String name;

  const PinMode._(this.name);
}
