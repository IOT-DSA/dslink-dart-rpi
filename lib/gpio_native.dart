library dslink.rpi.gpio.native;

import "dart:async";

import "package:rpi_gpio/rpi_gpio.dart" as Native;
import "package:rpi_gpio/rpi_hardware.dart" deferred as rpi;

import "gpio.dart";

class NativeGPIO implements GPIO {
  Native.Gpio gpio;
  Native.GpioHardware hardware;

  @override
  Future init() async {
    await rpi.loadLibrary();
    hardware = Native.Gpio.hardware = new rpi.RpiHardware();
    gpio = Native.Gpio.instance;
  }

  @override
  Future<int> getState(int pin) async {
    return hardware.digitalRead(pin);
  }

  @override
  Future setState(int pin, int value) async {
    gpio.pin(pin, Native.PinMode.output).value = value;
  }

  @override
  Future setMode(int pin, PinMode mode) async {
    if (mode == PinMode.INPUT) {
      gpio.pin(pin, Native.PinMode.input).mode = Native.PinMode.input;
    } else if (mode == PinMode.OUTPUT) {
      gpio.pin(pin, Native.PinMode.output).mode = Native.PinMode.output;
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

  @override
  Future<String> describe(int pin) async {
    return gpio.pin(pin).description;
  }

  @override
  Future<PinMode> getMode(int pin) async {
    var p = gpio.pin(pin);
    try {
      int value = p.value;
      return PinMode.INPUT;
    } catch (e) {
      return PinMode.OUTPUT;
    }
  }

  @override
  Future<int> readAnalogPin(int pin) async {
    return Native.Gpio.hardware.analogRead(pin);
  }

  @override
  Future<int> readDigitalByte() async {
    return Native.Gpio.hardware.digitalReadByte();
  }

  @override
  Future<int> readDigitalByte2() async {
    return Native.Gpio.hardware.digitalReadByte2();
  }

  @override
  Future writeAnalogPin(int pin, int value) async {
    Native.Gpio.hardware.analogWrite(pin, value);
  }

  @override
  Future writeDigitalByte(int value) async {
    Native.Gpio.hardware.digitalWriteByte(value);
  }

  @override
  Future writeDigitalByte2(int value) async {
    Native.Gpio.hardware.digitalWriteByte2(value);
  }
}
