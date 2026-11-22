import 'dart:js_interop';

@JS('AudioContext')
extension type _AudioContext._(JSObject _) implements JSObject {
  external factory _AudioContext();
  external _OscillatorNode createOscillator();
  external _GainNode createGain();
  external _AudioDestinationNode get destination;
  external void close();
}

@JS('OscillatorNode')
extension type _OscillatorNode._(JSObject _) implements JSObject {
  external _AudioParam get frequency;
  external void start([num when]);
  external void stop([num when]);
  external _OscillatorNode connect(JSObject destination);
  external set type(String value);
}

@JS('GainNode')
extension type _GainNode._(JSObject _) implements JSObject {
  external _AudioParam get gain;
  external _GainNode connect(JSObject destination);
}

@JS('AudioDestinationNode')
extension type _AudioDestinationNode._(JSObject _) implements JSObject {}

@JS('AudioParam')
extension type _AudioParam._(JSObject _) implements JSObject {
  external set value(num v);
}

_AudioContext? _ctx;
_OscillatorNode? _osc;
bool _highTone = false;
int _sirenInterval = 0;

void startWebAlarm() {
  try {
    _ctx = _AudioContext();
    final gain = _ctx!.createGain();
    gain.gain.value = 0.5;
    gain.connect(_ctx!.destination as JSObject);

    _osc = _ctx!.createOscillator();
    _osc!.type = 'square';
    _osc!.frequency.value = 800;
    _osc!.connect(gain as JSObject);
    _osc!.start();

    _highTone = false;
    _sirenInterval = _setInterval((() {
      if (_osc != null) {
        _highTone = !_highTone;
        _osc!.frequency.value = _highTone ? 1200 : 800;
      }
    }).toJS, 250);
  } catch (_) {}
}

@JS('setInterval')
external int _setInterval(JSFunction fn, int ms);

@JS('clearInterval')
external void _clearInterval(int id);

void stopWebAlarm() {
  try {
    if (_sirenInterval != 0) {
      _clearInterval(_sirenInterval);
      _sirenInterval = 0;
    }
    _osc?.stop();
    _osc = null;
    _ctx?.close();
    _ctx = null;
  } catch (_) {}
}
