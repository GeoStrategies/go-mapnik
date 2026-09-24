#!/bin/bash

cd `dirname $0`

cat > gen_import.go <<EOF
package mapnik
// #cgo CXXFLAGS: $(mapnik-config --cflags)
// #cgo LDFLAGS: $(mapnik-config --libs) -lboost_system
import "C"

const (
  fontPath = "$(mapnik-config --fonts)"
  pluginPath = "$(mapnik-config --input-plugins)"
)

EOF
