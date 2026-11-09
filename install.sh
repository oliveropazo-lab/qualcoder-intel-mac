#!/bin/bash
# Installs QualCoder from source on an Intel (x86_64) Mac.
# Usage: ./install.sh [install-folder]      (default: ~/QualCoder)
# Environment: QUALCODER_REF   git tag to install (default: 4.0)
#              QUALCODER_APPS  folder for QualCoder.app (default: ~/Applications)
set -euo pipefail

REF="${QUALCODER_REF:-4.0}"
TARGET="${1:-$HOME/QualCoder}"
APPS="${QUALCODER_APPS:-$HOME/Applications}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PYTHON="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3.12"

step() { printf '\n==> %s\n' "$1"; }
die() { printf '\nERROR: %s\n' "$1" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || die "This installer is for macOS."
[ "$(uname -m)" = x86_64 ] || die "This installer is for Intel Macs. Apple Silicon users should use the official .dmg."
[ -x "$PYTHON" ] || die "Python 3.12 not found. Install the macOS universal2 installer from
https://www.python.org/downloads/release/python-31210/ (3.12.10 is the last 3.12 with a macOS installer).
Python 3.13+ will not work: PyTorch has no Intel Mac wheels for it."
[ ! -e "$TARGET/venv" ] || die "$TARGET already contains an installation."

step "Downloading QualCoder $REF"
mkdir -p "$TARGET"
curl -fL --retry 5 -o "$TARGET/source.tar.gz" "https://github.com/ccbogel/QualCoder/archive/refs/tags/$REF.tar.gz"
tar -xzf "$TARGET/source.tar.gz" -C "$TARGET" --strip-components=1
rm "$TARGET/source.tar.gz"

step "Creating the virtual environment"
"$PYTHON" -m venv "$TARGET/venv"
VENV_PY="$TARGET/venv/bin/python3"
"$VENV_PY" -m pip install --quiet --upgrade pip

step "Installing dependencies (this can take 10-30 minutes)"
"$VENV_PY" -m pip install --prefer-binary \
  -c "$HERE/constraints-intel-mac.txt" -r "$TARGET/requirements.txt"
"$VENV_PY" -m pip check

step "Checking the libraries (the first import can take several minutes)"
"$VENV_PY" - <<'PY'
import numpy, torch
torch.from_numpy(numpy.array([1.0]))  # fails if torch and NumPy are incompatible
import faiss, fitz, pandas, sentence_transformers
from PyQt6 import QtWidgets
print("OK: torch", torch.__version__, "numpy", numpy.__version__)
PY

step "Creating the launcher"
cat > "$TARGET/start_qualcoder.sh" <<'SH'
#!/bin/bash
# Calls the venv's Python directly, so it keeps working if the folder is moved.
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR/src"
"$DIR/venv/bin/python3" -m qualcoder &
PID=$!
# Started from a script, the window can open behind the others.
( sleep 25; osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $PID) to true" >/dev/null 2>&1 ) &
wait $PID
SH
chmod +x "$TARGET/start_qualcoder.sh"

mkdir -p "$APPS"
APP="$APPS/QualCoder.app"
if [ -e "$APP" ]; then
  echo "$APP already exists; leaving it unchanged."
else
  # An AppleScript applet, because macOS can block a plain shell-script bundle
  # with "Operation not permitted" when the install folder is in Documents.
  osacompile -o "$APP" -e "do shell script \"nohup \" & quoted form of \"$TARGET/start_qualcoder.sh\" & \" > \\\"\$HOME/Library/Logs/QualCoder.log\\\" 2>&1 &\""
  cp "$TARGET/icons/qualcoder.icns" "$APP/Contents/Resources/applet.icns"
  plutil -replace CFBundleIdentifier -string local.qualcoder.app "$APP/Contents/Info.plist"
  codesign --force --deep -s - "$APP"
fi

step "Done"
echo "Open QualCoder from $APP or run: $TARGET/start_qualcoder.sh"
echo "In the Dock it appears as \"Python\"."
if [ ! -d /Applications/VLC.app ]; then
  echo "Optional: for full video support install VLC for Intel (macOS 64-bit) from https://www.videolan.org/vlc/"
fi
echo "If you see SSL errors, run \"/Applications/Python 3.12/Install Certificates.command\"."
