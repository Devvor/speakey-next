#!/usr/bin/env bash
# speakey Bark 3.0 vs SpeechAnalyzer A/B — run on the Mac (macOS 26, Apple Silicon).
#
#   bash scripts/bark-ab/run_ab.sh <clips_dir>
#
# clips_dir: audio clips of YOUR speech (wav or m4a; m4a is converted with afconvert).
#           Optional vocab.txt in clips_dir = your speakey vocabulary (comma/newline
#           separated) so SpeechAnalyzer gets the same vocab biasing the app gives it.
#
# Output: bark_ab_report.md in the repo root + per-engine raw outputs in scripts/bark-ab/out/.

set -euo pipefail

CLIPS_DIR="${1:?usage: run_ab.sh <clips_dir>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/out"
mkdir -p "$OUT"

[[ "$(uname -s)" == "Darwin" ]] || { echo "Run this on the Mac."; exit 1; }
SW_VERS_MINOR=$(sw_vers -productVersion | cut -d. -f1)
[[ "$SW_VERS_MINOR" -ge 26 ]] || { echo "Needs macOS 26 (SpeechAnalyzer). This Mac: $(sw_vers -productVersion)"; exit 1; }
[[ "$(uname -m)" == "arm64" ]] || { echo "Needs Apple Silicon (MLX)."; exit 1; }

# --- 1. Python env + model download -------------------------------------------
PY="$OUT/venv/bin/python"
if [[ ! -x "$PY" ]]; then
  python3 -m venv "$OUT/venv"
  "$OUT/venv/bin/pip" -q install --upgrade pip
  "$OUT/venv/bin/pip" -q install mlx mlx-audio constriction numpy soundfile soxr huggingface_hub
fi

MODEL_DIR="$OUT/bark-clean"
if [[ ! -f "$MODEL_DIR/model.bark" ]]; then
  "$PY" -m huggingface_hub.commands.hf download ConwayResearch/Underdog-Bark-3.0-Clean \
    --local-dir "$MODEL_DIR" \
    --include "model.bark" --include "bark_mlx.py" --include "bark_loader.py" \
    --include "mlx/*" --include "NOTICE" \
    || "$PY" -c "from huggingface_hub import snapshot_download; snapshot_download('ConwayResearch/Underdog-Bark-3.0-Clean', local_dir='$MODEL_DIR', allow_patterns=['model.bark','bark_mlx.py','bark_loader.py','mlx/*','NOTICE'])"
fi

# --- 2. Normalize clips to 16-bit wav ------------------------------------------
WORK="$OUT/clips"
rm -rf "$WORK"; mkdir -p "$WORK"
for f in "$CLIPS_DIR"/*.{wav,m4a,mp3,caf,aiff,aif}; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f")"; base="${base%.*}.wav"
  if [[ "$f" == *.wav ]]; then
    cp "$f" "$WORK/$base"
  else
    afconvert -f WAVE -d LEI16@24000 -c 1 "$f" "$WORK/$base"
  fi
done
shopt -s nullglob
CLIPS=("$WORK"/*.wav)
[[ ${#CLIPS[@]} -gt 0 ]] || { echo "No audio clips in $CLIPS_DIR"; exit 1; }
echo "Testing ${#CLIPS[@]} clip(s)"

VOCAB_ARGS=()
if [[ -f "$CLIPS_DIR/vocab.txt" ]]; then
  VOCAB_ARGS=(--vocab "$CLIPS_DIR/vocab.txt")
  echo "Using vocabulary from vocab.txt for SpeechAnalyzer"
fi

# --- 3. SpeechAnalyzer side ------------------------------------------------------
echo "== SpeechAnalyzer =="
SA_RAW="$OUT/sa_results.txt"; : > "$SA_RAW"
for clip in "${CLIPS[@]}"; do
  echo "--- $(basename "$clip")"
  swift "$HERE/sa_transcribe.swift" "$clip" "${VOCAB_ARGS[@]}" > "$OUT/last_sa.txt" 2> "$OUT/last_sa_err.txt" \
    || { echo "SA failed: $(cat "$OUT/last_sa_err.txt")"; }
  sa_time=$(grep -o 'sa_seconds [0-9.]*' "$OUT/last_sa_err.txt" | cut -d' ' -f2)
  sa_dur=$(grep -o 'audio_seconds [0-9.]*' "$OUT/last_sa_err.txt" | cut -d' ' -f2)
  sa_text=$(tr '\n' ' ' < "$OUT/last_sa.txt" | sed 's/  */ /g')
  echo "$(basename "$clip")"$'\t'"${sa_time:-ERR}"$'\t'"$sa_text" >> "$SA_RAW"
done

# --- 4. Bark side ----------------------------------------------------------------
echo "== Bark 3.0 Clean (MLX) =="
BARK_RAW="$OUT/bark_results.txt"
(cd "$MODEL_DIR" && "$PY" "$HERE/bark_transcribe.py" "${CLIPS[@]}" | tee "$BARK_RAW")

# --- 5. Report -------------------------------------------------------------------
"$PY" - "$SA_RAW" "$BARK_RAW" "$HERE/../.." "$CLIPS_DIR" <<'PYEOF'
import sys, datetime
sa_path, bark_path, repo_root, clips_dir = sys.argv[1:5]
sa = {}
for line in open(sa_path):
    parts = line.rstrip("\n").split("\t")
    if len(parts) >= 3: sa[parts[0]] = (parts[1], parts[2])
    elif len(parts) == 2: sa[parts[0]] = ("", parts[1])
bark = {}
for line in open(bark_path):
    parts = line.rstrip("\n").split("\t", 2)
    if len(parts) == 3: bark[parts[0]] = (parts[1], parts[2])

names = sorted(set(sa) | set(bark))
now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
lines = [f"# speakey A/B — SpeechAnalyzer vs Bark 3.0 Clean ({now})",
         f"Clips: {clips_dir} ({len(names)}). Timing = transcription wall seconds (SA includes analyzer warmup; Bark excludes model load).", ""]
for n in names:
    t_sa, x_sa = sa.get(n, ("", "(failed)"))
    t_b, x_b = bark.get(n, ("", "(failed)"))
    lines += [f"## {n}", "", f"**SpeechAnalyzer** ({t_sa}s): {x_sa}", "",
              f"**Bark Clean** ({t_b}s): {x_b}", "", ""]
out = "\n".join(lines)
open(f"{repo_root}/bark_ab_report.md", "w").write(out)
print(out)
PYEOF

echo ""
echo "Report saved: bark_ab_report.md (repo root)"
