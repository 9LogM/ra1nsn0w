#!/bin/bash
set -e

# --- Configuration ---
INSTALL_PREFIX="$(pwd)/_install"
DEPS_DIR="$(pwd)/deps"
OS_TYPE=$(uname -s)

log() {
    echo -e "\n\033[1;36m>>> $1\033[0m"
}

build_repo() {
    REPO_NAME="$1"
    DIR_NAME="${2:-$REPO_NAME}"
    REPO_URL="https://github.com/libimobiledevice/$REPO_NAME.git"
    
    if [[ "$3" == "tihmstar" ]]; then
        REPO_URL="https://github.com/tihmstar/$REPO_NAME.git"
    fi
    
    cd "$DEPS_DIR"
    
    if [ ! -d "$DIR_NAME" ]; then
        log "Cloning $REPO_NAME..."
        git clone --recursive "$REPO_URL" "$DIR_NAME"
    else
        log "$DIR_NAME already exists, updating..."
        cd "$DIR_NAME"
        git pull
        git submodule update --init --recursive
        cd ..
    fi

    cd "$DIR_NAME"
    log "Building $DIR_NAME (STATIC)..."
    
    if [ -f "Makefile" ]; then
        make distclean || true
    fi

    CONFIG_FLAGS="--prefix=$INSTALL_PREFIX --enable-static --disable-shared"

    if [ "$REPO_NAME" == "libirecovery" ]; then
        mkdir -p "$INSTALL_PREFIX/lib/udev/rules.d"
        CONFIG_FLAGS="$CONFIG_FLAGS --with-udevrulesdir=$INSTALL_PREFIX/lib/udev/rules.d"
    fi

    ./autogen.sh $CONFIG_FLAGS
    
    make -j$CPU_COUNT
    make install
    
    cd "$DEPS_DIR"
}

# --- OS Detection & Setup ---
if [ "$OS_TYPE" == "Darwin" ]; then
    echo ">>> Detected macOS. Setting up environment..."
    CPU_COUNT=$(sysctl -n hw.ncpu)

    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew not found. Please install it first."
        exit 1
    fi
    BREW_PREFIX=$(brew --prefix)

    echo ">>> Installing macOS dependencies..."
    brew install autoconf automake libtool pkg-config libplist libirecovery openssl libzip libusb

    export PKG_CONFIG_PATH="${BREW_PREFIX}/opt/openssl@3/lib/pkgconfig:${BREW_PREFIX}/opt/libzip/lib/pkgconfig:${BREW_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH"
    export CFLAGS="-I${BREW_PREFIX}/include $CFLAGS"
    export CXXFLAGS="-I${BREW_PREFIX}/include $CXXFLAGS"
    export LDFLAGS="-L${BREW_PREFIX}/lib $LDFLAGS"

elif [ "$OS_TYPE" == "Linux" ]; then
    echo ">>> Detected Linux. Setting up environment..."
    CPU_COUNT=$(nproc)

    if command -v apt-get &> /dev/null; then
        echo ">>> Installing basic build tools..."
        sudo apt-get update
        sudo apt-get install -y build-essential pkg-config autoconf automake libtool \
        libusb-1.0-0-dev libssl-dev libzip-dev libcurl4-openssl-dev git python3-dev
    fi

else
    echo "Error: Unsupported OS '$OS_TYPE'"
    exit 1
fi

# --- Common Environment Setup ---
export PKG_CONFIG_PATH="${INSTALL_PREFIX}/lib/pkgconfig:${INSTALL_PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
export PATH="${INSTALL_PREFIX}/bin:$PATH"
export CFLAGS="-I${INSTALL_PREFIX}/include $CFLAGS"
export CXXFLAGS="-I${INSTALL_PREFIX}/include $CXXFLAGS"
export LDFLAGS="-L${INSTALL_PREFIX}/lib $LDFLAGS"

# --- Execution ---
mkdir -p "$INSTALL_PREFIX"
mkdir -p "$DEPS_DIR"

if [ "$OS_TYPE" == "Linux" ]; then
    log "Building missing system libraries from source..."
    build_repo "libplist" "libplist"
    build_repo "libirecovery" "libirecovery"
fi

log "Building ra1nsn0w dependencies..."
build_repo "libgeneral" "libgeneral" "tihmstar"
build_repo "libinsn" "libinsn" "tihmstar"
build_repo "libfragmentzip" "libfragmentzip" "tihmstar"
build_repo "libfwkeyfetch" "libfwkeyfetch" "tihmstar"
build_repo "img4tool" "img4tool" "tihmstar"
build_repo "img3tool" "img3tool" "tihmstar"
build_repo "libpatchfinder" "libpatchfinder" "tihmstar"
build_repo "img1tool" "img1tool" "tihmstar"
build_repo "tsschecker" "tsschecker" "tihmstar"

cd .. 
log "Building ra1nsn0w (STATIC)..."

if [ -f "Makefile" ]; then
    make distclean || true
fi

./autogen.sh
./configure --prefix="$INSTALL_PREFIX" --enable-static --disable-shared

make -j$CPU_COUNT

echo ""
echo "--------------------------------------------------------"
echo "Build Complete!"
echo "--------------------------------------------------------"