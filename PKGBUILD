# Maintainer: CxOrg <https://github.com/CxOrg>
# Contributor: AG Projects <support@ag-projects.com>

pkgname=blink-qt
_pkgname=blink
pkgver=6.0.7
pkgrel=1
pkgdesc='Fully featured, easy to use SIP client with a Qt based UI'
arch=('x86_64' 'aarch64')
url='https://icanblink.com/'
license=('GPL-3.0-only')
depends=(
  'avahi'
  'python-application'
  'python-eventlib'
  'python-google-api-python-client'
  'python-google-auth-oauthlib'
  'python-lxml'
  'python-lxml-html-clean'
  'python-numpy'
  'python-oauth2client'
  'python-pgpy'
  'python-pyqt6'
  'python-pyqt6-webengine'
  'python-pyopenssl'
  'python-service-identity'
  'python-requests'
  'python-sipsimple>=5.3.2'
  'python-sqlobject'
  'python-standard-imghdr'
  'python-twisted'
  'python-zope-interface'
  'qt6-svg'
  'x11vnc'
)
makedepends=(
  'cython'
  'git'
  'libvncserver'
  'python-setuptools'
)
optdepends=(
  'python-gevent: gevent-based DNS lookup'
)
provides=('blink')
conflicts=('blink')
replaces=('blink')
source=(
  "${pkgname}::git+https://github.com/CxOrg/blink-qt.git"
  'blink.desktop'
)
sha256sums=('SKIP'
            'SKIP')

pkgver() {
  cd "${srcdir}/${pkgname}"
  # Read version from blink/__info__.py
  python3 -c "exec(open('blink/__info__.py').read()); print(__version__)"
}

prepare() {
  cd "${srcdir}/${pkgname}"
  # Remove any stale build artifacts from a previous in-place build
  rm -f blink/screensharing/_rfb.c
  rm -f blink/screensharing/_rfb.*.so
  rm -rf build
}

build() {
  cd "${srcdir}/${pkgname}"
  # Full build creates build/lib (with the compiled .so) and build/scripts-3.14
  python3 setup.py build
}

package() {
  cd "${srcdir}/${pkgname}"

  # Install the Python package, extension module, resources, and script
  python3 setup.py install --root="${pkgdir}/" --optimize=1 --skip-build

  # Desktop entry
  install -Dm644 "${srcdir}/blink.desktop" \
    "${pkgdir}/usr/share/applications/blink.desktop"

  # Man page
  install -Dm644 debian/blink.1 \
    "${pkgdir}/usr/share/man/man1/blink.1"

  # License
  install -Dm644 LICENSE \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
