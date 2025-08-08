#!/usr/bin/env bash
set -euo pipefail

# Colors
if [[ -t 1 ]]; then
  RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"; BOLD="\033[1m"; RESET="\033[0m"
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi
log()  { printf "${BLUE}==>${RESET} %b\n" "$*"; }
ok()   { printf "${GREEN}✓${RESET} %b\n" "$*"; }
warn() { printf "${YELLOW}!${RESET} %b\n" "$*"; }
err()  { printf "${RED}✗${RESET} %b\n" "$*" >&2; }

ENV="${1:-dev}"
OUT_DIR="docs"
[[ "$ENV" == "dev" ]] && OUT_DIR="docs-dev"

SRC="en/book.adoc"
THEME_DIR="theme"
THEME="$THEME_DIR/oreilly-theme.yml"
FONTS_DIR="$THEME_DIR/fonts"

# Kroki attrs:
# - Use public kroki.io (you can self-host later)
# - Force PNG so PDF has raster images
# - fetch-diagram downloads the rendered images into imagesoutdir
KROKI_ATTRS=(
  -a kroki-server-url=https://kroki.io
  -a kroki-default-format=png
  -a kroki-fetch-diagram
  -a kroki-timeout=60
)

log "${BOLD}Building (${ENV}) → ${OUT_DIR}${RESET}"
mkdir -p "$OUT_DIR/en"

# HTML
log "HTML (asciidoctor + kroki)"
asciidoctor \
  -r asciidoctor-kroki \
  -a source-highlighter=rouge \
  -a rouge-theme=github \
  -a stylesheet=../theme/default-theme.css \
  -a imagesoutdir="$OUT_DIR/en/images" \
  "${KROKI_ATTRS[@]}" \
  -o "$OUT_DIR/en/book.html" "$SRC"
ok "HTML → $OUT_DIR/en/book.html"

# PDF
log "PDF (asciidoctor-pdf + kroki)"
asciidoctor-pdf \
  -r asciidoctor-kroki \
  -a source-highlighter=rouge \
  -a pdf-theme="$THEME" \
  -a pdf-fontsdir="$FONTS_DIR" \
  -a imagesoutdir="$OUT_DIR/en/images" \
  "${KROKI_ATTRS[@]}" \
  -o "$OUT_DIR/en/book.pdf" "$SRC"
ok "PDF → $OUT_DIR/en/book.pdf"

# EPUB
log "EPUB3 (asciidoctor-epub3 + kroki)"
asciidoctor-epub3 \
  -r asciidoctor-kroki \
  -a source-highlighter=rouge \
  -a imagesoutdir="$OUT_DIR/en/images" \
  "${KROKI_ATTRS[@]}" \
  -o "$OUT_DIR/en/book.epub" "$SRC"
ok "EPUB → $OUT_DIR/en/book.epub"

printf "${GREEN}✅ Build complete:${RESET} %s (env=%s)\n" "$OUT_DIR/en/{book.html, book.pdf, book.epub}" "$ENV"
