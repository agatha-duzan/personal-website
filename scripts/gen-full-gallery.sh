#!/usr/bin/env bash
# Build the Full Gallery: generate web-optimized copies of every image in
# images/full_gallery/ into images/full_gallery/web/, then write the manifest
# the page reads. Your ORIGINALS in images/full_gallery/ are never modified.
#
# Run this whenever you add/remove images:
#     ./scripts/gen-full-gallery.sh
#
# A static site (GitHub Pages) can't list a directory at runtime, so the file
# list is baked into images/full_gallery/manifest.js at build time.
set -euo pipefail
cd "$(dirname "$0")/.."

dir="images/full_gallery"
webdir="$dir/web"
out="$dir/manifest.js"
mkdir -p "$webdir"

# Clear old optimized copies so removed originals don't linger.
rm -f "$webdir"/*.jpg

shopt -s nullglob nocaseglob
for f in "$dir"/*.jpg "$dir"/*.jpeg "$dir"/*.png "$dir"/*.webp "$dir"/*.gif; do
	[ -f "$f" ] || continue
	base="$(basename "$f")"
	name="${base%.*}"
	# -auto-orient: honour phone EXIF rotation before stripping metadata.
	# -flatten onto white: transparent PNGs get a white (page-coloured) bg.
	# ~1400px long edge keeps it crisp on screen at a fraction of the size.
	convert "$f" -auto-orient -resize '1400x1400>' \
		-background white -flatten -strip -interlace Plane -quality 82 \
		"$webdir/$name.jpg"
done
shopt -u nocaseglob nullglob

{
	echo "// AUTO-GENERATED — do not edit by hand."
	echo "// Regenerate with: ./scripts/gen-full-gallery.sh"
	echo "window.FULL_GALLERY = ["
	find "$webdir" -maxdepth 1 -type f -iname '*.jpg' -printf '%f\n' | LC_ALL=C sort | sed 's/.*/  "&",/'
	echo "];"
} > "$out"

count=$(grep -c '^  "' "$out" || true)
echo "Optimized $count image(s) into $webdir/ and wrote $out."
