# QualCoder on Intel Macs

An unofficial installer for [QualCoder](https://github.com/ccbogel/QualCoder) 4.0 on Intel (x86_64) Macs. It is not affiliated with the QualCoder project.

QualCoder 4.0 ships a macOS `.dmg` for Apple Silicon only. Installing from source on an Intel Mac fails or breaks the AI features unless a few package versions are pinned. This installer applies those pins.

## Requirements

- An Intel Mac (tested on macOS 14.8 Sonoma)
- [Python 3.12.10](https://www.python.org/downloads/release/python-31210/), using the macOS universal2 installer
- About 2 GB of free disk space

Python 3.13 or newer will not work, because PyTorch has no Intel Mac wheels for it.

## Install

```bash
git clone https://github.com/oliveropazo-lab/qualcoder-intel-mac.git
cd qualcoder-intel-mac
./install.sh
```

This installs QualCoder in `~/QualCoder` and creates `~/Applications/QualCoder.app`. To use another folder, run `./install.sh /path/to/folder`. The installer downloads QualCoder from the official repository; this repository does not contain QualCoder's code.

The first launch can take several minutes. In the Dock, QualCoder appears as "Python".

## What it pins, and why

| Package | Version | Reason |
| --- | --- | --- |
| torch | 2.2.2 | Last release with macOS x86_64 wheels |
| numpy | 1.26.4 | torch 2.2.2 fails with NumPy 2 ("Numpy is not available"), which breaks AI embeddings |
| pandas, scipy, contourpy | 3.0.6, 1.17.1, 1.3.3 | Latest versions compatible with NumPy 1.26 |
| pymupdf | 1.28.2 | Last release with a macOS x86_64 wheel |
| cryptography | 48.0.1 | Universal2 wheel, so Rust is not needed |

Pip runs with `--prefer-binary` so it does not try to compile packages from source.

## Optional

- Video: install [VLC](https://www.videolan.org/vlc/) for Intel (macOS 64-bit).
- SSL errors: run `/Applications/Python 3.12/Install Certificates.command`.

## Known limits

Tested on one Intel MacBook Air (macOS 14.8.4), including a clean install and launch of QualCoder 4.0. These pins may stop working if QualCoder's requirements change; `QUALCODER_REF` selects another QualCoder tag, but only 4.0 has been tested.
