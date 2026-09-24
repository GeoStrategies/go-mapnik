package mapnik_test

import (
	"bytes"
	"math"
	"strings"
	"testing"

	"github.com/fawick/go-mapnik/mapnik"
)

const stylesheet = "../sampledata/stylesheet.xml"

const webMercator = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs"

func loadSample(t *testing.T) *mapnik.Map {
	t.Helper()
	m := mapnik.NewMap(256, 256)
	if err := m.Load(stylesheet); err != nil {
		t.Fatal(err)
	}
	if err := m.ZoomAll(); err != nil {
		t.Fatal(err)
	}
	return m
}

func TestVersion(t *testing.T) {
	if v := mapnik.Version(); !strings.HasPrefix(v, "Mapnik ") {
		t.Errorf("Version() = %q, want a %q prefix", v, "Mapnik ")
	}
}

func TestRenderToMemoryPng(t *testing.T) {
	m := loadSample(t)
	defer m.Free()
	png, err := m.RenderToMemoryPng()
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.HasPrefix(png, []byte("\x89PNG")) {
		t.Errorf("RenderToMemoryPng() returned %d bytes that are not a PNG", len(png))
	}
}

func TestClone(t *testing.T) {
	m := loadSample(t)
	defer m.Free()
	c := m.Clone()
	defer c.Free()
	if c.SRS() != m.SRS() {
		t.Errorf("clone SRS() = %q, want %q", c.SRS(), m.SRS())
	}
	if err := c.ZoomAll(); err != nil {
		t.Fatal(err)
	}
	want, _ := m.RenderToMemoryPng()
	got, _ := c.RenderToMemoryPng()
	if !bytes.Equal(got, want) {
		t.Error("clone renders differently from the map it was copied from")
	}
}

func TestProjectionForward(t *testing.T) {
	m := mapnik.NewMap(256, 256)
	defer m.Free()
	m.SetSRS(webMercator)
	p := m.Projection()
	defer p.Free()
	got := p.Forward(mapnik.Coord{X: -122.4194, Y: 37.7749})
	want := mapnik.Coord{X: -13627665.27, Y: 4547675.35}
	if math.Abs(got.X-want.X) > 0.01 || math.Abs(got.Y-want.Y) > 0.01 {
		t.Errorf("Forward(-122.4194, 37.7749) = %.2f, %.2f; want %.2f, %.2f", got.X, got.Y, want.X, want.Y)
	}
}
