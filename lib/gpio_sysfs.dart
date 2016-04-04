library dslink.rpi.gpio_sysfs;

import "dart:async";
import "dart:io";

import "gpio.dart";

class SysfsGPIO extends GPIO {
  @override
  Future<int> getState(int pin) async {
    var file = new File("/sys/class/gpio/gpio${pin}/value");
    if (!(await file.exists())) {
      await new File("/sys/class/gpio/export").writeAsString(pin.toString());
    }
    return int.parse((await file.readAsString()).trim());
  }

  @override
  Future init() async {
    var dir = new Directory("/sys/class/gpio");
    if (!(await dir.exists())) {
      throw new Exception("Sysfs GPIO not supported.");
    }
  }

  @override
  Future setMode(int pin, PinMode mode) async {
    var file = new File("/sys/class/gpio/gpio${pin}/direction");
    if (!(await file.exists())) {
      await new File("/sys/class/gpio/export").writeAsString(pin.toString());
    }
    await file.writeAsString(mode == PinMode.INPUT ? "in" : "out");
  }

  @override
  Future setState(int pin, int value) async {
    var file = new File("/sys/class/gpio/gpio${pin}/value");
    if (!(await file.exists())) {
      await new File("/sys/class/gpio/export").writeAsString(pin.toString());
    }
    await setMode(pin, PinMode.OUTPUT);
    await file.writeAsString(value.toString());
  }

  @override
  Stream<int> watchState(int pin) {
    return new Stream<int>.empty();
  }

  @override
  Future writeSoftTone(int pin, int frequency) async {
  }

  @override
  Future startSoftTone(int pin) async {
  }

  @override
  Future stopSoftTone(int pin) async {
  }

  @override
  Future<bool> isSoftTone(int pin) async {
    return false;
  }
}
