# speakey A/B: SpeechAnalyzer vs Underdog Bark 3.0 Clean

Head-to-head test of speakey's current engine (Apple SpeechAnalyzer, with the
same vocab biasing the app uses) against Underdog Bark 3.0 Clean (163→180 MB
Parakeet descendant, CC-BY 4.0, English only). Run on the Mac — macOS 26,
Apple Silicon, Xcode 26 installed.

## Steps

1. Record 5–10 clips of YOUR real dictation (30 s each is plenty). Use Voice
   Memos or QuickTime. Mix it up:
   - normal sentences you'd actually dictate to speakey
   - your jargon / names / tickers (the stuff that gets mis-transcribed)
   - a few with "um"s and restarts
2. Drop them in a folder, e.g. `~/Desktop/ab-clips/`. wav/m4a both fine.
3. Optional but recommended: copy your speakey vocabulary into
   `~/Desktop/ab-clips/vocab.txt` (same comma/newline format as the app's
   vocabulary box) so SpeechAnalyzer gets its usual hint advantage.
4. From the repo root:

   ```bash
   bash scripts/bark-ab/run_ab.sh ~/Desktop/ab-clips
   ```

   First run downloads the Bark model (~180 MB) and unpacks it once (~6 GB RAM,
   cached). Everything stays on-device; nothing is uploaded.

5. Read `bark_ab_report.md` (repo root) — side-by-side transcripts + timings.
   Send it back and I'll call the verdict.

## What each side measures

- **SpeechAnalyzer side** = exactly what speakey does today: SpeechTranscriber
  + AnalysisContext vocab biasing, file-based transcription.
- **Bark side** = `bark_mlx.py` from Conway's own repo, model loaded once,
  per-clip transcription timed (model load excluded).

Known asymmetries (keep in mind reading the report):

- Bark gets **no vocab biasing** — its output is raw. In the app you'd still
  run it through the existing LLM cleanup, which can fix names/jargon.
- Bark is **English only**. If you dictate in other languages, SpeechAnalyzer
  keeps those — Bark could only be the English default.
- Bark writes fillers with the base model; **Clean** (what this tests) strips
  them, matching dictation use.
- SA timing includes analyzer setup per clip; Bark's excludes model load.
  Both are sub-second-ish either way — judge on accuracy first.
