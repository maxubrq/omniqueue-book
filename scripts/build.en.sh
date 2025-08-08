#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# Colors
# -------------------------
if [[ -t 1 ]]; then
  RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"; BOLD="\033[1m"; RESET="\033[0m"
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi
log()  { printf "${BLUE}==>${RESET} %b\n" "$*"; }
ok()   { printf "${GREEN}✓${RESET} %b\n" "$*"; }
warn() { printf "${YELLOW}!${RESET} %b\n" "$*"; }
err()  { printf "${RED}✗${RESET} %b\n" "$*" >&2; }

# -------------------------
# Inputs / paths
# -------------------------
ENV="${1:-dev}"
OUT_DIR="docs"
[[ "$ENV" == "dev" ]] && OUT_DIR="docs-dev"

SRC="en/book.adoc"
SRC_DIR="$(dirname "$SRC")"      # -> en
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT_EN_DIR="$REPO_ROOT/$OUT_DIR/en"
OUT_IMAGES="$OUT_EN_DIR/images"
REL_OUT_IMAGES="../$OUT_DIR/en/images"   # for EPUB: relative from SRC_DIR ("en")

THEME_DIR="theme"
THEME="$THEME_DIR/oreilly-theme.yml"
FONTS_DIR="$THEME_DIR/fonts"

# -------------------------
# Build prep
# -------------------------
log "${BOLD}Building (${ENV}) → ${OUT_DIR}${RESET}"
mkdir -p "$OUT_EN_DIR" "$OUT_IMAGES"

# Copy STATIC images (book-cover.png, logos, etc.) from source to OUT_IMAGES
if [[ -d "$SRC_DIR/images" ]]; then
  log "Sync static images → $OUT_IMAGES"
  rsync -a --delete "$SRC_DIR/images/" "$OUT_IMAGES/"
else
  warn "No static images directory at $SRC_DIR/images"
fi

# Kroki attrs (server-side rendering; no Chrome/Puppeteer)
KROKI_ATTRS=(
  -a kroki-server-url=https://kroki.io
  -a kroki-default-format=png
  -a kroki-fetch-diagram
  -a kroki-timeout=60
)

# -------------------------
# HTML
# Keep doc's :imagesdir: images (nice relative links)
# Diagrams are written to OUT_IMAGES via imagesoutdir
# -------------------------
log "HTML (asciidoctor + kroki)"
asciidoctor \
  -r asciidoctor-kroki \
  -a source-highlighter=rouge \
  -a rouge-theme=github \
  -a stylesheet=../theme/default-theme.css \
  -a imagesoutdir="$OUT_IMAGES" \
  -a imagesdir="images/images" \
  "${KROKI_ATTRS[@]}" \
  -o "$OUT_EN_DIR/book.html" "$SRC"
ok "HTML → $OUT_EN_DIR/book.html"

# -------------------------
# PDF
# Embed images from ABSOLUTE output images dir
# -------------------------
log "PDF (asciidoctor-pdf + kroki)"
asciidoctor-pdf \
  -r asciidoctor-kroki \
  -a source-highlighter=rouge \
  -a pdf-theme="$THEME" \
  -a pdf-fontsdir="$FONTS_DIR" \
  -a imagesoutdir="$OUT_IMAGES" \
  -a imagesdir="$OUT_IMAGES" \
  "${KROKI_ATTRS[@]}" \
  -o "$OUT_EN_DIR/book.pdf" "$SRC"
ok "PDF → $OUT_EN_DIR/book.pdf"

# -------------------------
# EPUB
# IMPORTANT: EPUB resolves imagesdir relative to docdir (en/)
# so pass a RELATIVE path from en/ → OUT_IMAGES
# -------------------------
log "EPUB3 (asciidoctor-epub3 + kroki)"
asciidoctor-epub3 \
  -r asciidoctor-kroki \
  -a source-highlighter=rouge \
  -a imagesoutdir="$OUT_IMAGES" \
  -a imagesdir="$REL_OUT_IMAGES" \
  "${KROKI_ATTRS[@]}" \
  -o "$OUT_EN_DIR/book.epub" "$SRC"
ok "EPUB → $OUT_EN_DIR/book.epub"

printf "${GREEN}✅ Build complete:${RESET} %s (env=%s)\n" "$OUT_EN_DIR/{book.html, book.pdf, book.epub}" "$ENV"
