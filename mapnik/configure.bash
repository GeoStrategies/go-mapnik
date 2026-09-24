#!/bin/bash
set -e

cd `dirname $0`

if command -v mapnik-config >/dev/null; then
  # cgo rejects the -f*-prefix-map flags some distributions build Mapnik with
  CXXFLAGS=$(mapnik-config --cflags | sed -e 's/ -fdebug-prefix-map=[^ ]*//g' -e 's/ -ffile-prefix-map=[^ ]*//g')
  LDFLAGS="$(mapnik-config --libs) -lboost_system"
  FONTS=$(mapnik-config --fonts)
  PLUGINS=$(mapnik-config --input-plugins)
else
  # Mapnik 4 installs a CMake package config instead of mapnik-config
  CMAKE_DIR=$(dirname "$(find /usr/lib /usr/local/lib -name mapnikTargets.cmake 2>/dev/null | head -1)")
  if [ "$CMAKE_DIR" = . ]; then
    echo "configure.bash: found neither mapnik-config nor the Mapnik CMake package config" >&2
    exit 1
  fi
  PREFIX=$(cd "$CMAKE_DIR/../../../.." && pwd)
  CXXFLAGS="-std=c++17 $(sed -n 's/.*INTERFACE_COMPILE_DEFINITIONS "\(.*\)"/\1/p' "$CMAKE_DIR/mapnikTargets.cmake" | tr ';' '\n' | sort -u | sed 's/^/-D/' | tr '\n' ' ')"
  LDFLAGS=-lmapnik
  FONTS=$PREFIX$(sed -n 's|.*MAPNIK_FONTS_DIR "${PACKAGE_PREFIX_DIR}\([^"]*\)".*|\1|p' "$CMAKE_DIR/mapnikConfig.cmake")
  PLUGINS=$PREFIX$(sed -n 's|.*MAPNIK_PLUGINS_DIR_[A-Z]* "${PACKAGE_PREFIX_DIR}\([^"]*\)".*|\1|p' "$CMAKE_DIR"/mapnikPlugins-*.cmake | head -1)
fi

cat > gen_import.go <<EOF
package mapnik
// #cgo CXXFLAGS: $CXXFLAGS
// #cgo LDFLAGS: $LDFLAGS
import "C"

const (
  fontPath = "$FONTS"
  pluginPath = "$PLUGINS"
)

EOF
