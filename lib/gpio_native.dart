library dslink.rpi.gpio.native;

import "dart:async";

import "package:rpi_gpio/rpi_gpio.dart" as Native;
import "package:rpi_gpio/rpi_hardware.dart" deferred as rpi;

import "gpio.dart";

class NativeGPIO implements GPIO {
  Native.Gpio gpio;

  @override
  Future init() async {
    await rpi.loadLibrary();
    Native.Gpio.hardware = new rpi.RpiHardware();
    gpio = Native.Gpio.instance;
  }

  @override
  Future<int> getState(int pin) async {
    return gpio.pin(pin).value;
  }

  @override
  Future setState(int pin, int value) async {
    gpio.pin(pin).value = value;
  }

  @override
  Future setMode(int pin, PinMode mode) async {
    if (mode == PinMode.INPUT) {
      gpio.pin(pin).mode = Native.PinMode.input;
    } else if (mode == PinMode.OUTPUT) {
      gpio.pin(pin).mode = Native.PinMode.output;
    }
  }

  @override
  Stream<int> watchState(int pin) {
    return gpio.pin(pin).events.map((Native.PinEvent event) {
      return event.value;
    });
  }

  @override
  Future startSoftTone(int pin) async {
    gpio.pin(pin).startSoftTone();
  }

  @override
  Future stopSoftTone(int pin) async {
    gpio.pin(pin).stopSoftTone();
  }

  @override
  Future writeSoftTone(int pin, int frequency) async {
    gpio.pin(pin).writeSoftTone(frequency);
  }

  @override
  Future<bool> isSoftTone(int pin) async {
    return gpio.pin(pin).isSoftToneMode;
  }
}
