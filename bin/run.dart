import "dart:async";
import "dart:io";

import "package:dslink/dslink.dart";
import "package:dslink/nodes.dart";

import "package:rpi_gpio/rpi_gpio.dart";
import "package:rpi_gpio/rpi_hardware.dart" deferred as rpi;

LinkProvider link;
Gpio gpio;

const PIN_VALUE_ZERO = const {"value": 0};
const PIN_VALUE_ONE = const {"value": 1};

final Map<String, dynamic> DEFAULT_NODES = {
  "Execute_Command": {
    r"$is": "executeCommand",
    r"$invokable": "write",
    r"$name": "Execute Command",
    r"$params": [{"name": "command", "type": "string"}],
    r"$result": "values",
    r"$columns": [
      {"name": "exitCode", "type": "number"},
      {"name": "stdout", "type": "string", "editor": "textarea"}
    ]
  },
  "GPIO": {
    "Create_Pin_Watcher": {
      r"$is": "createPinWatcher",
      r"$invokable": "write",
      r"$name": "Create Pin Watcher",
      r"$result": "values",
      r"$params": [
        {"name": "name", "type": "string"},
        {"name": "pin", "type": "number", "default": 1},
        {"name": "mode", "type": "enum[input,output]", "default": "input"}
      ]
    },
    "Get_Pin_Value": {
      r"$is": "getPinValue",
      r"$invokable": "write",
      r"$name": "Get Pin Value",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$columns": [{"name": "value", "type": "number"}],
      r"$result": "values"
    },
    "Read_RC_Circut": {
      r"$is": "readRCCircut",
      r"$invokable": "write",
      r"$name": "Read RC Circut",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$columns": [{"name": "value", "type": "number"}],
      r"$result": "values"
    },
    "Start_Soft_Tone": {
      r"$is": "startSoftTone",
      r"$invokable": "write",
      r"$name": "Start Soft Tone",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$result": "values"
    },
    "Stop_Soft_Tone": {
      r"$is": "stopSoftTone",
      r"$invokable": "write",
      r"$name": "Stop Soft Tone",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$result": "values"
    },
    "Write_Soft_Tone": {
      r"$is": "writeSoftTone",
      r"$invokable": "write",
      r"$name": "Write Soft Tone",
      r"$params": [
        {"name": "pin", "type": "number", "default": 1},
        {"name": "frequency", "type": "number", "default": 1}
      ],
      r"$result": "values"
    },
    "Set_Pin_Value": {
      r"$is": "setPinValue",
      r"$invokable": "write",
      r"$name": "Set Pin Value",
      r"$params": [
        {"name": "pin", "type": "number", "default": 1},
        {"name": "value", "type": "number", "default": 0}
      ],
      r"$result": "values"
    },
  }
};

main(List<String> args) async {
  if (!isRaspberryPi) {
    print("ERROR: This link only works on the Raspberry Pi.");
    exit(1);
  }

  await rpi.loadLibrary();
  Gpio.hardware = new rpi.RpiHardware();
  gpio = Gpio.instance;

  link = new LinkProvider(args,
    "RaspberryPi-",
    defaultNodes: DEFAULT_NODES,
    profiles: {
      "executeCommand": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) async {
        var cmd = params["command"];
        var args = ["-c", cmd];
        var result = await Process.run("bash", args);

        return {
          "exitCode": result.exitCode,
          "stdout": result.stdout.toString()
        };
      }),
      "togglePinValue": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) {
        var x = link[new Path(path).parentPath];
        var l = x.lastValueUpdate.value;
        x.updateValue(l == 0 ? 1 : 0);
      }),
      "setPinValue": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) {
        try {
          int pn = params["pin"].toInt();
          int value = params["value"].toInt();
          var pin = gpio.pin(pn, output);
          pin.value = value;
        } catch (e) {}
        return {};
      }),
      "getPinValue": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) {
        try {
          int pn = params["pin"].toInt();
          var pin = gpio.pin(pn, input);
          var val = pin.value;

          if (val == 0) {
            return PIN_VALUE_ZERO;
          } else if (val == 1) {
            return PIN_VALUE_ONE;
          } else {
            return {"value": val};
          }
        } catch (e) {}
        return {};
      }),
      "startSoftTone": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) async {
        try {
          int pn = params["pin"].toInt();
          var pin = gpio.pin(pn, output);
          if (!pin.isSoftToneMode) {
            pin.startSoftTone();
          }
        } catch (e) {}
        return {};
      }),
      "writeSoftTone": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) async {
        try {
          int pn = params["pin"].toInt();
          var pin = gpio.pin(pn, output);
          if (!pin.isSoftToneMode) {
            pin.startSoftTone();
          }
          num freq = params["frequency"];
          if (freq is! num) {
            return {};
          }
          freq = freq.toInt();
          pin.writeSoftTone(freq);
        } catch (e) {}
        return {};
      }),
      "readRCCircut": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) async {
        try {
          int pn = params["pin"].toInt();
          var pin = gpio.pin(pn, output);
          pin.value = 0;
          await new Future.delayed(const Duration(milliseconds: 100));
          pin.mode = PinMode.input;
          var reading = 0;
          while (pin.value == 0) {
            await null;
            reading++;
          }
          return {"value": reading};
        } catch (e) {}
        return {};
      }),
      "createPinWatcher": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) {
        var m = {
          r"$is": "pinWatcher",
          r"$name": params["name"],
          r"$gpio_pin": params["pin"],
          r"$gpio_mode": params["mode"]
        };

        var rp = "${params["name"].replaceAll(' ', '_')}_${params['pin']}";

        link.addNode("/GPIO/${rp}", m);

        link.save();
      }),
      "pinWatcher": (String path) => new PinWatcherNode(path),
      "deletePinWatcher": (String path) => new DeleteActionNode.forParent(
        path, link.provider),
      "stopSoftTone": (String path) => new SimpleActionNode(
        path, (Map<String, dynamic> params) async {
        try {
          int pn = params["pin"].toInt();
          var pin = gpio.pin(pn, output);
          if (pin.isSoftToneMode) {
            pin.stopSoftTone();
          }
        } catch (e) {}
        return {};
      })
    }, autoInitialize: false);

  link.init();

  for (var n in DEFAULT_NODES.keys) {
    if (n == "GPIO") {
      continue;
    }
    link.removeNode("/${n}");
    link.addNode("/${n}", DEFAULT_NODES[n]);
  }

  for (var n in DEFAULT_NODES["GPIO"].keys) {
    link.removeNode("/GPIO/${n}");
    link.addNode("/GPIO/${n}", DEFAULT_NODES["GPIO"][n]);
  }

  link.connect();
}

class PinWatcherNode extends SimpleNode {
  Pin pin;
  StreamSubscription listener;
  StreamSubscription frequencyListener;

  PinWatcherNode(String path) : super(path);

  @override
  void onCreated() {
    var pinn = configs[r"$gpio_pin"];
    var mode = configs[r"$gpio_mode"];

    if (mode == null) {
      mode = "input";
    }

    if (mode == "input") {
      pin = gpio.pin(pinn, input);

      link.removeNode("${path}/Value");
      link.addNode("${path}/Value", {r"$type": "number", "?value": pin.value});

      var pv = link["${path}/Value"];
      listener = pin.events.listen((e) {
        pv.updateValue(e.value);
      });

      pv.updateValue(pin.value);
    } else if (mode == "output") {
      pin = gpio.pin(pinn, output);

      link.removeNode("${path}/Value");
      link.addNode("${path}/Value", {
        r"$type": "number",
        "?value": 0,
        r"$writable": "write",
        "Toggle": {
          r"$is": "togglePinValue",
          r"$invokable": "write",
          r"$params": [],
          r"$result": "values"
        }
      });

      link.addNode("${path}/Frequency", {
        r"$type": "number",
        "?value": 0,
        r"$writable": "write"
      });

      listener =
        link.onValueChange("${path}/Value").listen((ValueUpdate update) {
          var value = update.value;

          if (value == null) {
            value = 0;
          }

          if (value is bool) {
            value = value ? 1 : 0;
          }

          pin.value = value;
        });

      frequencyListener =
        link.onValueChange("${path}/Frequency").listen((ValueUpdate update) {
          var value = update.value;

          if (value == null) {
            value = 0;
          }

          if (value is bool) {
            value = value ? 261 : 0;
          }

          if (!pin.isSoftToneMode) {
            pin.startSoftTone();
          }

          pin.writeSoftTone(value);
        });
    }

    link.removeNode("${path}/Delete");
    link.addNode("${path}/Delete", {
      r"$is": "deletePinWatcher",
      r"$invokable": "write",
      r"$result": "values",
      r"$params": []
    });
  }

  @override
  void onRemoving() {
    if (listener != null) {
      listener.cancel();
      listener = null;
    }

    if (frequencyListener != null) {
      frequencyListener.cancel();
      frequencyListener = null;
    }

    if (pin.isSoftToneMode) {
      pin.stopSoftTone();
    }
  }

  @override
  Map save() {
    var m = super.save();
    m.remove("Delete");
    m.remove("Value");
    return m;
  }
}
