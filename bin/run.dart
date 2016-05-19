import "dart:async";

import "package:dslink/dslink.dart";
import "package:dslink/nodes.dart";

import "package:args/args.dart";

import "package:dslink_rpi/gpio.dart";

import "package:dslink_rpi/gpio_native.dart";
import "package:dslink_rpi/gpio_sysfs.dart";

LinkProvider link;
GPIO gpio;

const PIN_VALUE_ZERO = const [const [0]];
const PIN_VALUE_ONE = const [const [1]];

final Map<String, dynamic> DEFAULT_NODES = {
  "gpio": {
    r"$name": "GPIO",
    "createPinWatcher": {
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
    "getPinValue": {
      r"$is": "getPinValue",
      r"$invokable": "write",
      r"$name": "Get Pin Value",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$columns": [{"name": "value", "type": "number"}],
      r"$result": "values"
    },
    "readRCCircut": {
      r"$is": "readRCCircut",
      r"$invokable": "write",
      r"$name": "Read RC Circut",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$columns": [{"name": "value", "type": "number"}],
      r"$result": "values"
    },
    "startSoftTone": {
      r"$is": "startSoftTone",
      r"$invokable": "write",
      r"$name": "Start Soft Tone",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$result": "values"
    },
    "stopSoftTone": {
      r"$is": "stopSoftTone",
      r"$invokable": "write",
      r"$name": "Stop Soft Tone",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$result": "values"
    },
    "writeSoftTone": {
      r"$is": "writeSoftTone",
      r"$invokable": "write",
      r"$name": "Write Soft Tone",
      r"$params": [
        {"name": "pin", "type": "number", "default": 1},
        {"name": "frequency", "type": "number", "default": 1}
      ],
      r"$result": "values"
    },
    "setPinValue": {
      r"$is": "setPinValue",
      r"$invokable": "write",
      r"$name": "Set Pin Value",
      r"$params": [
        {"name": "pin", "type": "number", "default": 1},
        {"name": "value", "type": "number", "default": 0}
      ],
      r"$result": "values"
    },
    "setPinMode": {
      r"$is": "setPinMode",
      r"$invokable": "write",
      r"$name": "Set Pin Mode",
      r"$params": [
        {
          "name": "pin",
          "type": "number",
          "default": 1
        },
        {
          "name": "mode",
          "type": "enum[in,out]",
          "default": "in"
        }
      ]
    },
    "analogWrite": {
      r"$is": "analogWrite",
      r"$invokable": "write",
      r"$name": "Write Analog",
      r"$params": [
        {"name": "pin", "type": "number", "default": 1},
        {"name": "value", "type": "number", "default": 0}
      ],
      r"$result": "values"
    },
    "analogRead": {
      r"$is": "analogRead",
      r"$invokable": "write",
      r"$name": "Read Analog",
      r"$params": [{"name": "pin", "type": "number", "default": 1}],
      r"$columns": [{"name": "value", "type": "number"}],
      r"$result": "values"
    }
  }
};

int readInt(input) {
  if (input is String) {
    return num.parse(input).toInt();
  } else if (input is num) {
    return input.toInt();
  } else if (input == null) {
    return 0;
  }
  throw new Exception("Invalid Number");
}

main(List<String> args) async {
  link = new LinkProvider(args,
    "RaspberryPi-",
    defaultNodes: DEFAULT_NODES,
    profiles: {
      "togglePinValue": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
        var x = link[new Path(path).parentPath];
        var l = x.lastValueUpdate.value;
        x.updateValue(l == 0 ? 1 : 0);
      }),
      "setPinValue": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);
        int value = readInt(params["value"]);
        await gpio.setState(pn, value);

        return [];
      }),
      "getPinValue": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);
        var val = await gpio.getState(pn);

        if (val == 0) {
          return PIN_VALUE_ZERO;
        } else if (val == 1) {
          return PIN_VALUE_ONE;
        } else {
          return [[val]];
        }
      }),
      "setPinMode": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);
        var mode = params["mode"].toString().toLowerCase();
        PinMode m = PinMode.OUTPUT;

        if (mode == "in" || mode == "input") {
          m = PinMode.INPUT;
        } else if (mode == "out" || mode == "output") {
          m = PinMode.OUTPUT;
        }

        await gpio.setMode(pn, m);

        return [];
      }),
      "startSoftTone": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);
        if (!(await gpio.isSoftTone(pn))) {
          await gpio.startSoftTone(pn);
        }

        return [];
      }),
      "writeSoftTone": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);

        if (!(await gpio.isSoftTone(pn))) {
          await gpio.startSoftTone(pn);
        }
        num freq = params["frequency"];
        if (freq is! num) {
          return [];
        }
        await gpio.writeSoftTone(pn, freq.toInt());

        return [];
      }),
      "readRCCircut": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);

        await gpio.setState(pn, 0);
        await new Future.delayed(const Duration(milliseconds: 100));
        await gpio.setMode(pn, PinMode.OUTPUT);
        var reading = 0;
        while ((await gpio.getState(pn)) == 0) {
          reading++;
        }
        return [[reading]];
      }),
      "createPinWatcher": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
        var m = {
          r"$is": "pinWatcher",
          r"$name": params["name"],
          r"$gpio_pin": params["pin"],
          r"$gpio_mode": params["mode"]
        };

        var rp = "${params["name"].replaceAll(' ', '_')}_${params['pin']}";

        link.addNode("/gpio/${rp}", m);

        link.save();
      }),
      "pinWatcher": (String path) => new PinWatcherNode(path),
      "deletePinWatcher": (String path) => new DeleteActionNode.forParent(
        path,
        link.provider as MutableNodeProvider,
        onDelete: () => link.save()
      ),
      "stopSoftTone": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);
        if (await gpio.isSoftTone(pn)) {
          await gpio.stopSoftTone(pn);
        }
        return [];
      }),
      "analogRead": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);
        return [[await gpio.readAnalogPin(pn)]];
      }),
      "analogWrite": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
        int pn = readInt(params["pin"]);
        int value = readInt(params["value"]);

        await gpio.writeAnalogPin(pn, value);

        return [];
      }),
      "gpioValue": (String path) => new ValueNode(path),
      "gpioFrequency": (String path) => new FrequencyNode(path)
    }, autoInitialize: false);

  var argp = new ArgParser();
  argp.addOption("gpio_driver", allowed: [
    "native",
    "sysfs"
  ], defaultsTo: "native");

  link.configure(argp: argp, optionsHandler: (ArgResults results) {
    String driver = results["gpio_driver"];
    if (driver == "sysfs") {
      gpio = new SysfsGPIO();
    } else {
      gpio = new NativeGPIO();
    }
  });

  if (gpio == null) {
    gpio = new NativeGPIO();
  }

  await gpio.init();

  link.init();

  for (var n in DEFAULT_NODES.keys) {
    if (n == "gpio" || n.startsWith(r"$") || n.startsWith("@")) {
      continue;
    }
    link.removeNode("/${n}");
    link.addNode("/${n}", DEFAULT_NODES[n]);
  }

  for (var n in DEFAULT_NODES["gpio"].keys) {
    if (n.toString().startsWith(r"$") || n.toString().startsWith("@")) {
      continue;
    }
    link.removeNode("/gpio/${n}");
    link.addNode("/gpio/${n}", DEFAULT_NODES["gpio"][n]);
  }

  link.connect();
}

class PinWatcherNode extends SimpleNode {
  int pn;
  StreamSubscription listener;

  PinWatcherNode(String path) : super(path);

  @override
  onCreated() async {
    pn = configs[r"$gpio_pin"];
    var mode = configs[r"$gpio_mode"];

    if (mode == null) {
      mode = "input";
    }

    if (mode == "input") {
      await gpio.setMode(pn, PinMode.INPUT);
      link.removeNode("${path}/value");
      link.addNode("${path}/value", {
        r"$type": "number",
        "?value": await gpio.getState(pn)
      });

      var pv = link["${path}/value"];
      listener = gpio.watchState(pn).listen((e) {
        pv.updateValue(e);
      });

      pv.updateValue(await gpio.getState(pn));
    } else if (mode == "output") {
      await gpio.setMode(pn, PinMode.OUTPUT);
      link.removeNode("${path}/value");
      ValueNode valNode = link.addNode("${path}/value", {
        r"$is": "gpioValue",
        r"$type": "number",
        "?value": 0,
        r"$writable": "write",
        "toggle": {
          r"$name": "Toggle",
          r"$is": "togglePinValue",
          r"$invokable": "write",
          r"$params": [],
          r"$result": "values"
        }
      });

      FrequencyNode freqNode = link.addNode("${path}/frequency", {
        r"$is": "gpioFrequency",
        r"$type": "number",
        "?value": 0,
        r"$writable": "write"
      });

      valNode.pin = freqNode.pin = pn;
    }

    link.removeNode("${path}/delete");
    link.addNode("${path}/delete", {
      r"$is": "deletePinWatcher",
      r"$invokable": "write",
      r"$result": "values",
      r"$params": []
    });
  }

  @override
  onRemoving() async {
    if (listener != null) {
      listener.cancel();
      listener = null;
    }

    if (await gpio.isSoftTone(pn)) {
      await gpio.stopSoftTone(pn);
    }
  }

  @override
  Map save() {
    var m = super.save();
    m.remove("delete");
    m.remove("value");
    m.remove("frequency");
    return m;
  }
}

class ValueNode extends SimpleNode {
  int pin;

  ValueNode(String path) : super(path);

  @override
  onSetValue(value) {
    try {
      var i = readInt(value);

      new Future(() async {
        await gpio.setState(pin, i);
        updateValue(i);
      });
    } catch (e) {
    }
    return true;
  }
}

class FrequencyNode extends SimpleNode {
  int pin;

  FrequencyNode(String path) : super(path);

  @override
  onSetValue(value) {
    if (value is bool) {
      value = value ? 261 : 0;
    }

    try {
      var i = readInt(value);

      new Future(() async {
        if (!(await gpio.isSoftTone(pin))) {
          await gpio.startSoftTone(pin);
        }
        await gpio.writeSoftTone(pin, i);

        updateValue(i);
      });
    } catch (e) {
    }
    return true;
  }
}
