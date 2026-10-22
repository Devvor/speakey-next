#!/usr/bin/env python3
"""Bark 3.0 Clean batch transcriber for the speakey A/B test (Apple Silicon, MLX).

Loads the model ONCE, then transcribes every given clip. Emits one line per clip:

    <clip_basename>\t<seconds>\t<transcript>

Model setup/download is handled by run_ab.sh. First run unpacks model.bark into
an MLX folder (~6 GB RAM, one time); cached afterwards.

  python3 bark_transcribe.py clip1.wav clip2.wav ...
"""

import os
import sys
import time

import numpy as np
import soundfile as sf

HERE = os.path.dirname(os.path.abspath(__file__))


def main() -> int:
    clips = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not clips:
        print("usage: bark_transcribe.py <clip.wav> [...]", file=sys.stderr)
        return 2

    sys.path.insert(0, HERE)
    import bark_mlx  # noqa: E402  (vendored from ConwayResearch/Underdog-Bark-3.0-Clean)

    print("loading bark model (first run unpacks ~6 GB, cached after)...", file=sys.stderr)
    t0 = time.time()
    model = bark_mlx.load_model()
    print(f"model ready in {time.time() - t0:.1f}s", file=sys.stderr)

    for path in clips:
        try:
            wave, sr = sf.read(path, dtype="float32", always_2d=True)
        except Exception as e:  # unreadable clip: report, keep going
            print(f"{os.path.basename(path)}\tERROR\t{e}", flush=True)
            continue
        mono = wave.mean(1)
        t0 = time.time()
        text = bark_mlx.transcribe(model, mono, sr)
        elapsed = time.time() - t0
        print(f"{os.path.basename(path)}\t{elapsed:.3f}\t{text}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
