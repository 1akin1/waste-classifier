// lib/main.dart
//
// Waste Classification — runs fully on-device (offline) with TFLite.
// Flow: pick an image → resize to 224x224 → feed to the model → show class + confidence.
//
// IMPORTANT — preprocessing match:
//   The model file has a Rescaling(1/127.5, -1) layer baked INSIDE it (train_and_export.py).
//   So we DO NOT touch the pixels here; we send the raw 0-255 values as floats.
//   Because training and phone preprocessing are identical, the classic
//   "works in Python but misbehaves on the phone" bug does not happen.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_litert/flutter_litert.dart';

void main() => runApp(const WasteApp());

class WasteApp extends StatelessWidget {
  const WasteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste Classifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32), // eco green
        useMaterial3: true,
      ),
      home: const ClassifierPage(),
    );
  }
}

class ClassifierPage extends StatefulWidget {
  const ClassifierPage({super.key});
  @override
  State<ClassifierPage> createState() => _ClassifierPageState();
}

class _ClassifierPageState extends State<ClassifierPage> {
  static const int inputSize = 224;

  Interpreter? _interpreter;
  List<String> _labels = [];
  File? _image;
  String? _label;
  double _confidence = 0;
  bool _busy = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
      await Interpreter.fromAsset('assets/waste_classifier.tflite');
      final raw = await rootBundle.loadString('assets/labels.txt');
      _labels = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      setState(() {});
    } catch (e, st) {
      debugPrint('MODEL LOAD FAILED: $e\n$st');
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1024);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _label = null;
      _busy = true;
    });
    await _classify(File(picked.path));
    setState(() => _busy = false);
  }

  Future<void> _classify(File file) async {
    final interpreter = _interpreter;
    if (interpreter == null) return;

    // 1) Decode + resize to 224x224
    final decoded = img.decodeImage(await file.readAsBytes());
    if (decoded == null) return;
    final resized = img.copyResize(decoded, width: inputSize, height: inputSize);

    // 2) [1, 224, 224, 3] float input — raw 0-255 (normalization is inside the model)
    final input = List.generate(
      1,
          (_) => List.generate(
        inputSize,
            (y) => List.generate(inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r.toDouble(), p.g.toDouble(), p.b.toDouble()];
        }),
      ),
    );

    // 3) Output [1, num_classes] — softmax probabilities
    final output =
    List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    interpreter.run(input, output);

    // 4) Highest-probability class
    final probs = (output[0] as List).cast<double>();
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    setState(() {
      _label = _labels[best];
      _confidence = probs[best] * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = _interpreter != null && _labels.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Waste Classifier')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? const Center(
                    child: Text('Select or take a photo',
                        style: TextStyle(color: Colors.black54)))
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_label != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.recycling, size: 36),
                  title: Text(_label!,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  subtitle:
                  Text('Confidence: ${_confidence.toStringAsFixed(1)}%'),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: ready ? () => _pick(ImageSource.camera) : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: ready ? () => _pick(ImageSource.gallery) : null,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Failed to load model:\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              )
            else if (!ready)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Loading model...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54)),
              ),
          ],
        ),
      ),
    );
  }
}