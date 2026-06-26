# Waste Classifier

An on-device (offline) Flutter app that classifies a photo of a waste item into
one of nine material types using a TensorFlow Lite model. Pick an image from the
camera or gallery, and the app predicts the waste category with a confidence
score — entirely on the device, with no internet connection required.

> **License:** All Rights Reserved. This project is **not** open source. See [LICENSE](LICENSE).

## Screenshots

<p align="center"> 

<img width="1080" height="2400" alt="Screenshot_20260626_214810" src="https://github.com/user-attachments/assets/bf347f90-4ee7-4e7d-864b-b5166ede3312" />
<img width="1080" height="2400" alt="Screenshot_20260626_214832" src="https://github.com/user-attachments/assets/ea34c14e-4c3b-451b-8f11-240c02e27247" />
<img width="1080" height="2400" alt="Screenshot_20260626_214844" src="https://github.com/user-attachments/assets/d125f7de-0ad6-42da-9ffe-1282c0b3df9f" />
 
</p>

## Features

- On-device inference with TensorFlow Lite / LiteRT — works fully offline.
- Pick an image from the **camera** or the **gallery**.
- Predicts one of nine waste categories with a confidence percentage.
- Preprocessing (rescaling) is baked into the model, so training and inference
  match exactly — avoiding the common "works in Python but not on the phone" bug.

## Waste categories

The model recognizes these nine classes (see `assets/labels.txt`):

`Cardboard`, `Food Organics`, `Glass`, `Metal`, `Miscellaneous Trash`,
`Paper`, `Plastic`, `Textile Trash`, `Vegetation`

## How it works

1. The selected image is decoded and resized to **224x224**.
2. Raw 0-255 RGB pixel values are sent to the model as floats. Normalization is
   handled inside the model by a `Rescaling(1/127.5, -1)` layer, so no manual
   preprocessing is needed in the app.
3. The model outputs softmax probabilities over the nine classes; the app shows
   the highest-probability class and its confidence.

## Tech stack

- **Flutter** (Dart)
- **flutter_litert** — LiteRT (formerly TensorFlow Lite) inference, bundles a
  modern native runtime
- **image_picker** — camera and gallery selection
- **image** — image decoding and resizing

## Requirements

- Flutter SDK (Dart 3.x)
- Android SDK with a recent platform installed; a device or emulator (API 26+)
- JDK 17 (the Android build targets JVM 17)

## Getting started

```bash
flutter pub get
flutter run
```

The model and labels are already bundled under `assets/`, so no extra download
is needed.

## Project structure

```
lib/main.dart                      App UI and inference logic
assets/waste_classifier.tflite     Trained TFLite model
assets/labels.txt                  Class labels (one per line)
android/                           Android build configuration
```

## Model & dataset

The bundled model was trained on the **RealWaste** dataset, licensed under
**CC BY 4.0**. If you reference this work, please cite the dataset authors:

> S. Single, S. Iranmanesh, and R. Raad, "RealWaste: A Novel Real-Life Data Set
> for Landfill Waste Classification Using Deep Learning," Information, vol. 14,
> no. 12, p. 633, 2023. https://doi.org/10.3390/info14120633
>
> UCI Machine Learning Repository: https://doi.org/10.24432/C5SS4G

> **Note on predictions:** if the app loads but predicts the wrong class, first
> check that the order of `assets/labels.txt` matches the model's output order.
> A mismatch shifts every prediction, and that is a labeling issue rather than a
> code bug.

## License

All Rights Reserved. You may view this repository for reference, but you may not
use, copy, modify, or distribute any part of it without prior written
permission. See [LICENSE](LICENSE) for the full terms. The dataset attribution
above is required independently of these terms.

## Author

Zihni <Your Surname>
