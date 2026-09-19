#!/bin/bash
#
# Install the SIP SIMPLE client SDK on Arch Linux.
#
# Arch ships FFmpeg 5.1+ which removed AVCodec->pix_fmts and
# AVCodec->supported_framerates.  The bundled PJSIP 2.10 still uses those
# fields, so this script applies fix_ffmpeg_pix_fmts.patch (which switches
# to avcodec_get_supported_config) before building.
#
# If an importable sipsimple of at least $SIPSIMPLE_MIN_VERSION is already
# present, the (expensive) PJSIP build is skipped and the SDK is reused.

set -e

SIPSIMPLE_VERSION="5.3.3.1"           # tagged python3-sipsimple release to build
SIPSIMPLE_MIN_VERSION="5.3.2"         # minimum acceptable already-installed version
PJSIP_VERSION="2.10"
SIPCLIENTS_VERSION="5.2.3"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Reuse an already-installed SDK ----------------------------------------
if python3 - "$SIPSIMPLE_MIN_VERSION" <<'PY'
import re, sys
try:
    import sipsimple
except Exception:
    sys.exit(1)
def parse(v):
    return [int(x) for x in re.findall(r"\d+", v)]
sys.exit(0 if parse(sipsimple.__version__) >= parse(sys.argv[1]) else 1)
PY
then
    echo "SIP SIMPLE SDK $(python3 -c 'import sipsimple; print(sipsimple.__version__)') already installed - skipping build."
    exit 0
fi

echo "SIP SIMPLE SDK not found (or older than $SIPSIMPLE_MIN_VERSION); building it..."

# --- C build + runtime dependencies (pacman) --------------------------------
PACMAN_BUILD_DEPS=(
    cython python-build python-installer python-wheel
    alsa-lib ffmpeg libvpx opencore-amr openssl opus x264 v4l-utils
    util-linux-libs sqlite libvncserver
)
PACMAN_RUNTIME_DEPS=(
    python-application python-eventlib python-gnutls python-msrplib
    python-otr python-xcaplib python-twisted python-lxml python-dnspython
    python-dateutil python-gevent avahi
)

echo "Installing pacman build dependencies..."
sudo pacman -S --needed --noconfirm "${PACMAN_BUILD_DEPS[@]}"

echo "Installing pacman runtime dependencies..."
sudo pacman -S --needed --noconfirm "${PACMAN_RUNTIME_DEPS[@]}"

# --- Build & install the SDK -----------------------------------------------
BUILD_DIR="$HOME/work"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

srcdir="python3-sipsimple-$SIPSIMPLE_VERSION"
if [ ! -d "$srcdir" ]; then
    echo "Downloading python3-sipsimple $SIPSIMPLE_VERSION..."
    wget -N "https://github.com/AGProjects/python3-sipsimple/archive/refs/tags/$SIPSIMPLE_VERSION.tar.gz"
    tar zxf "$SIPSIMPLE_VERSION.tar.gz"
    rm -f "$SIPSIMPLE_VERSION.tar.gz"
fi

cd "$srcdir"
echo "Fetching SDK C dependencies (PJSIP $PJSIP_VERSION)..."
chmod +x ./get_dependencies.sh
./get_dependencies.sh "$PJSIP_VERSION"

echo "Applying FFmpeg compatibility patch..."
patch -p1 < "$HERE/fix_ffmpeg_pix_fmts.patch"

echo "Building SIP SIMPLE SDK..."
pip3 install --break-system-packages .

cd "$BUILD_DIR"

# --- Command line SIP clients (optional companion tools) -------------------
echo "Installing sipclients3 $SIPCLIENTS_VERSION..."
pip3 install --break-system-packages "https://github.com/AGProjects/sipclients3/archive/refs/tags/$SIPCLIENTS_VERSION.tar.gz"

echo "SIP SIMPLE SDK installation complete."
