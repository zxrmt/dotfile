#!/usr/bin/env python3
import argparse
import os
import queue
import subprocess
import tempfile
import threading
import time
import wave

import numpy as np
import sounddevice as sd
from pynput import keyboard
import mlx_whisper

## Remember to config permisson on wezterm first

KEY_MAP = {
    "f6": keyboard.Key.f6,
    "f7": keyboard.Key.f7,
    "f8": keyboard.Key.f8,
    "f9": keyboard.Key.f9,
    "f10": keyboard.Key.f10,
    "f11": keyboard.Key.f11,
    "f12": keyboard.Key.f12,
    "right_shift": keyboard.Key.shift_r,
    "left_shift": keyboard.Key.shift_l,
    "caps_lock": keyboard.Key.caps_lock,
    "right_option": keyboard.Key.alt_r,
    "left_option": keyboard.Key.alt_l,
    "right_cmd": keyboard.Key.cmd_r,
    "left_cmd": keyboard.Key.cmd_l,
    "right_ctrl": keyboard.Key.ctrl_r,
}


def _escape_for_applescript(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def type_into_frontmost_app(text: str, *, activate_app: str | None, press_enter: bool) -> None:
    text = text.replace("\n", " ").strip()
    if not text:
        return

    # Chunk to avoid AppleScript keystroke weirdness with long strings
    chunks = [text[i:i+180] for i in range(0, len(text), 180)]

    cmd = ["osascript"]
    if activate_app:
        cmd += ["-e", f'tell application "{_escape_for_applescript(activate_app)}" to activate']

    for ch in chunks:
        cmd += ["-e", f'tell application "System Events" to keystroke "{_escape_for_applescript(ch)}"']

    if press_enter:
        cmd += ["-e", 'tell application "System Events" to key code 36']  # Return

    subprocess.run(cmd, check=False)


class LazyRecorder:
    """
    Mic is NOT opened until start() is called.
    Mic is closed immediately in stop_to_wav().
    This makes the macOS mic indicator show only while recording.
    """
    def __init__(self, samplerate: int = 16000, device: int | None = None):
        self.samplerate = samplerate
        self.device = device
        self.recording = False
        self._frames: list[np.ndarray] = []
        self._stream: sd.InputStream | None = None
        self._lock = threading.Lock()

    def _callback(self, indata, frames, time_info, status):
        # Keep callback very defensive (never throw)
        try:
            with self._lock:
                if self.recording:
                    self._frames.append(indata.copy())
        except Exception:
            pass

    def start(self):
        with self._lock:
            if self.recording:
                return
            self._frames = []
            self.recording = True

            # Open mic stream ONLY now
            self._stream = sd.InputStream(
                samplerate=self.samplerate,
                channels=1,
                dtype="float32",
                device=self.device,
                callback=self._callback,
            )
            self._stream.start()

    def stop_to_wav(self) -> str | None:
        # Grab stream reference and frames safely, then close mic outside lock
        with self._lock:
            if not self.recording:
                return None
            self.recording = False
            stream = self._stream
            self._stream = None
            frames = self._frames
            self._frames = []

        # Close mic ASAP → indicator disappears
        if stream is not None:
            try:
                stream.stop()
            finally:
                stream.close()

        if not frames:
            return None

        audio = np.concatenate(frames, axis=0).reshape(-1)
        audio_i16 = (np.clip(audio, -1.0, 1.0) * 32767.0).astype(np.int16)

        fd, path = tempfile.mkstemp(prefix="ptt_", suffix=".wav")
        os.close(fd)
        with wave.open(path, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(self.samplerate)
            wf.writeframes(audio_i16.tobytes())

        return path

    def close(self):
        # In case we're shutting down while recording
        with self._lock:
            stream = self._stream
            self._stream = None
            self.recording = False
        if stream is not None:
            try:
                stream.stop()
            finally:
                stream.close()


def transcribe_file(path: str, model: str, language: str | None) -> str:
    kwargs = {"path_or_hf_repo": model}
    if language:
        kwargs["language"] = language

    try:
        out = mlx_whisper.transcribe(path, **kwargs)
    except TypeError:
        kwargs.pop("language", None)
        out = mlx_whisper.transcribe(path, **kwargs)

    return (out.get("text") or "").strip()


def main():
    ap = argparse.ArgumentParser(description="Hold-to-talk → local MLX Whisper → type into Terminal/iTerm.")
    ap.add_argument("--key", default="right_ctrl", choices=sorted(KEY_MAP.keys()), help="Hold this key to record.")
    ap.add_argument("--model", default="mlx-community/whisper-large-v3-mlx",
                    help="HF repo or local model path.")
    ap.add_argument("--language", default="en", help="Optional language code (en, vi, ...).")
    ap.add_argument("--activate", default=None, help='Activate app before typing, e.g. "Terminal" or "iTerm2".')
    ap.add_argument("--enter", action="store_true", help="Press Enter after typing.")
    ap.add_argument("--no-type", action="store_true", help="Only print transcription, don’t type.")
    ap.add_argument("--device", type=int, default=None, help="Optional input device index (sounddevice).")
    ap.add_argument("--samplerate", type=int, default=16000, help="Mic samplerate (default 16000).")
    args = ap.parse_args()

    push_key = KEY_MAP[args.key]

    injecting = threading.Event()   # ignore key events while we inject keystrokes
    cmd_down = threading.Event()    # quit only on CMD+ESC (not ESC alone)

    jobs: "queue.Queue[str]" = queue.Queue()

    recorder = LazyRecorder(samplerate=args.samplerate, device=args.device)


    def worker():
        while True:
            wav_path = jobs.get()
            try:
                text = transcribe_file(wav_path, args.model, args.language)
                if text:
                    print(text, flush=True)
                    if not args.no_type:
                        injecting.set()
                        try:
                            type_into_frontmost_app(text, activate_app=args.activate, press_enter=args.enter)
                        finally:
                            # small delay so injected keys don't trip our listener
                            time.sleep(0.05)
                            injecting.clear()
            except Exception as e:
                print(f"[ERR] worker: {e}", flush=True)
            finally:
                try:
                    os.remove(wav_path)
                except OSError:
                    pass
                jobs.task_done()

    threading.Thread(target=worker, daemon=True).start()

    print(f"Push-to-talk ready. Hold {args.key.upper()} to record, release to transcribe.")
    print("Quit: CMD+ESC\n")

    def on_press(k):
        try:
            if injecting.is_set():
                return

            if k in (keyboard.Key.cmd, keyboard.Key.cmd_l, keyboard.Key.cmd_r):
                cmd_down.set()
                return

            if k == keyboard.Key.esc and cmd_down.is_set():
                return False  # stop listener

            if k == push_key and not recorder.recording:
                print("[REC] ...", flush=True)
                recorder.start()
        except Exception as e:
            print(f"[ERR] on_press: {e}", flush=True)

    def on_release(k):
        try:
            if k in (keyboard.Key.cmd, keyboard.Key.cmd_l, keyboard.Key.cmd_r):
                cmd_down.clear()
                return

            if injecting.is_set():
                return

            if k == push_key and recorder.recording:
                print("[REC] stop", flush=True)
                wav_path = recorder.stop_to_wav()
                if wav_path:
                    jobs.put(wav_path)
        except Exception as e:
            print(f"[ERR] on_release: {e}", flush=True)

    try:
        with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
            listener.join()
    finally:
        recorder.close()


if __name__ == "__main__":
    main()
