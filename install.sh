#!/bin/bash
#
# Install blink-qt and all dependencies on Arch Linux.
#
# This script handles the full dependency chain in the correct order:
#   1. Official repo dependencies (pacman)
#   2. AUR-only dependencies (yay)
#   3. python-sipsimple (built from source with FFmpeg compat patch)
#   4. python-sqlobject (AUR)
#   5. blink-qt (built from this repo's PKGBUILD)
#
# Arch ships FFmpeg 5.1+ which removed AVCodec->pix_fmts and
# AVCodec->supported_framerates.  The bundled PJSIP 2.10 still uses those
# fields, so fix_ffmpeg_pix_fmts.patch (which switches to
# avcodec_get_supported_config) is applied before building sipsimple.

set -e

SIPSIMPLE_MIN_VERSION="5.3.2"         # minimum acceptable already-installed version

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helper: check if a python module is importable ------------------------
have_module() {
    python3 -c "import $1" 2>/dev/null
}

# --- Helper: check sipsimple version ----------------------------------------
sipsimple_ok() {
    python3 - "$SIPSIMPLE_MIN_VERSION" <<'PY'
import re, sys
try:
    import sipsimple
except Exception:
    sys.exit(1)
def parse(v):
    return [int(x) for x in re.findall(r"\d+", v)]
sys.exit(0 if parse(sipsimple.__version__) >= parse(sys.argv[1]) else 1)
PY
}

# ============================================================================
# Step 1: Official repo dependencies (pacman)
# ============================================================================
echo "=== Step 1: Installing official repo dependencies ==="

PACMAN_DEPS=(
    avahi
    cython
    git
    libvncserver
    python-build
    python-installer
    python-setuptools
    python-wheel
    python-google-api-python-client
    python-google-auth-oauthlib
    python-lxml
    python-lxml-html-clean
    python-numpy
    python-oauth2client
    python-pgpy
    python-pyqt6
    python-pyqt6-webengine
    python-pyopenssl
    python-service-identity
    python-requests
    python-standard-imghdr
    python-twisted
    python-zope-interface
    qt6-svg
    x11vnc
    # sipsimple build deps
    alsa-lib ffmpeg libvpx opencore-amr openssl opus x264 v4l-utils
    util-linux-libs sqlite
)

sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"

# ============================================================================
# Step 2: AUR-only dependencies (yay)
# ============================================================================
echo "=== Step 2: Installing AUR dependencies ==="

# python-msrplib is built from source (AUR version 0.21.1 has broken URL)
AUR_DEPS=(
    python-application
    python-eventlib
    python-gnutls
    python-otr
    python-xcaplib
    python-dnspython
    python-gevent
    python-zope-event
    python-pydispatcher
    python-formencode
    python-sqlobject
)

# Install AUR deps that aren't already installed
NEEDS_AUR=()
for pkg in "${AUR_DEPS[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        NEEDS_AUR+=("$pkg")
    fi
done

if [ ${#NEEDS_AUR[@]} -gt 0 ]; then
    echo "Installing via yay: ${NEEDS_AUR[*]}"
    yay -S --needed "${NEEDS_AUR[@]}"
else
    echo "All AUR dependencies already installed."
fi

# ============================================================================
# Step 2b: python-msrplib (built as pacman package - AUR 0.21.1 has broken URL)
# ============================================================================
echo "=== Step 2b: Building python-msrplib ==="

if pacman -Q python-msrplib >/dev/null 2>&1; then
    echo "python-msrplib already installed - skipping."
else
    MSRPDIR="$HERE/msrplib"
    cd "$MSRPDIR"
    rm -rf src pkg *.pkg.tar.* *.log
    makepkg
    sudo pacman -U --noconfirm python-msrplib-*.pkg.tar.zst
    cd "$HERE"
    echo "python-msrplib installed successfully."
fi

# ============================================================================
# Step 3: python-sipsimple (built as pacman package with FFmpeg patch)
# ============================================================================
echo "=== Step 3: Building python-sipsimple ==="

if pacman -Q python-sipsimple >/dev/null 2>&1 && sipsimple_ok; then
    echo "python-sipsimple $(python3 -c 'import sipsimple; print(sipsimple.__version__)') already installed - skipping."
else
    SIPDIR="$HERE/sipsimple"
    cd "$SIPDIR"
    rm -rf src pkg *.pkg.tar.* *.log
    makepkg
    sudo pacman -U --noconfirm python-sipsimple-*.pkg.tar.zst
    cd "$HERE"
    echo "python-sipsimple installed successfully."
fi

# ============================================================================
# Step 4: blink-qt (built from this repo's PKGBUILD)
# ============================================================================
echo "=== Step 4: Building and installing blink-qt ==="

cd "$HERE"
rm -rf src pkg *.pkg.tar.* *.log

makepkg

echo "=== Installing blink-qt package ==="
sudo pacman -U --noconfirm blink-qt-*.pkg.tar.zst

echo ""
echo "=== Installation complete ==="
echo "Run blink with: /usr/bin/blink"
