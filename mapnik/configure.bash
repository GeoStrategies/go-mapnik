#!/bin/bash

[ -f mapnik_c_api.cpp ] || curl -LO https://raw.githubusercontent.com/geostrategies/mapnik-c-api/copy-map/mapnik_c_api.cpp
[ -f mapnik_c_api.h ] || curl -LO https://raw.githubusercontent.com/geostrategies/mapnik-c-api/copy-map/mapnik_c_api.h

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

go install -x
