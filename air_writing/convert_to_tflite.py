#!/usr/bin/env python3
"""Convertit le modele Keras air writing vers TensorFlow Lite."""

from __future__ import annotations

import argparse
from pathlib import Path

import tensorflow as tf


def _build_representative_dataset():
    """Genere un petit dataset representatif pour la quantification int8."""

    for _ in range(200):
        sample = tf.random.uniform(shape=(1, 28, 28, 1), minval=0.0, maxval=1.0, dtype=tf.float32)
        yield [sample]


def convert_model(input_path: Path, output_path: Path, quantize_int8: bool) -> None:
    """Convertit un modele .h5 vers .tflite et ecrit le fichier de sortie."""

    keras_model = tf.keras.models.load_model(input_path)
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    if quantize_int8:
        converter.representative_dataset = _build_representative_dataset
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.float32
        converter.inference_output_type = tf.float32

    tflite_model = converter.convert()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(tflite_model)


def parse_args() -> argparse.Namespace:
    """Parse les arguments CLI."""

    script_dir = Path(__file__).resolve().parent
    default_input = script_dir / "model" / "model.h5"
    default_output = script_dir.parent / "assets" / "models" / "air_writing.tflite"

    parser = argparse.ArgumentParser(description="Conversion Keras (.h5) -> TFLite pour Ma3ak.")
    parser.add_argument(
        "--input",
        type=Path,
        default=default_input,
        help=f"Chemin du modele .h5 (defaut: {default_input})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=default_output,
        help=f"Chemin du modele .tflite (defaut: {default_output})",
    )
    parser.add_argument(
        "--int8",
        action="store_true",
        help="Active une quantification int8 (avec dataset representatif aleatoire).",
    )
    return parser.parse_args()


def main() -> None:
    """Point d'entree du script."""

    args = parse_args()
    convert_model(args.input, args.output, args.int8)
    mode = "int8" if args.int8 else "float/optimise"
    print(f"[OK] Modele converti ({mode}) -> {args.output}")


if __name__ == "__main__":
    main()
