#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
OUT_DIR="docs"
[[ "$ENV" == "dev" ]] && OUT_DIR="docs-dev"

SRC="en/book.adoc"
THEME_DIR="theme"
THEME="$THEME_DIR/oreilly-theme.yml"
FONTS_DIR="$THEME_DIR/fonts"

mkdir -p "$OUT_DIR/en"

asciidoctor -a stylesheet=../theme/oreilly-theme.css -o "$OUT_DIR/en/book.html" "$SRC"

asciidoctor-pdf \
  -a pdf-theme="$THEME" \
  -a pdf-fontsdir="$FONTS_DIR" \
  -o "$OUT_DIR/en/book.pdf" "$SRC"

asciidoctor-epub3 -o "$OUT_DIR/en/book.epub" "$SRC"

echo "✅ Build complete: $OUT_DIR/en/{book.html, book.pdf, book.epub} (env=$ENV)"
