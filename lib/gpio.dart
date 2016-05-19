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

  Future<int> readAnalogPin(int pin);
  Future writeAnalogPin(int pin, int value);

  Future<int> readDigitalByte();
  Future<int> readDigitalByte2();

  Future writeDigitalByte(int value);
  Future writeDigitalByte2(int value);

  Future setPullUpDown(int pin, PullUpDown state);
}

class PinMode {
  static const PinMode INPUT = const PinMode._("INPUT");
  static const PinMode OUTPUT = const PinMode._("OUTPUT");

  final String name;

  const PinMode._(this.name);
}

class PullUpDown {
  static const PullUpDown OFF = const PullUpDown._("OFF", 0);
  static const PullUpDown DOWN = const PullUpDown._("DOWN", 1);
  static const PullUpDown UP = const PullUpDown._("UP", 2);

  final String name;
  final int id;

  const PullUpDown._(this.name, this.id);
}
