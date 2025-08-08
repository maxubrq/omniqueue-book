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

ENV="${1:-dev}"
OUT_DIR="docs"
[[ "$ENV" == "dev" ]] && OUT_DIR="docs-dev"

SRC="en/book.adoc"
THEME_DIR="theme"
THEME="$THEME_DIR/oreilly-theme.yml"
FONTS_DIR="$THEME_DIR/fonts"

# Ensure Puppeteer knows which Chromium to use (works in CI too)
if [[ -z "${PUPPETEER_EXECUTABLE_PATH:-}" ]]; then
  if command -v npx &>/dev/null; then
    CHROMIUM_PATH="$(npx --yes @puppeteer/browsers path chromium 2>/dev/null || true)"
    if [[ -n "$CHROMIUM_PATH" && -x "$CHROMIUM_PATH" ]]; then
      export PUPPETEER_EXECUTABLE_PATH="$CHROMIUM_PATH"
      log "Using Chromium at $PUPPETEER_EXECUTABLE_PATH"
    else
      warn "PUPPETEER_EXECUTABLE_PATH not set and Chromium path not found via puppeteer. Mermaid may fail."
    fi
  else
    warn "npx not available; cannot auto-detect Chromium path."
  fi
fi

log "${BOLD}Building (${ENV}) → ${OUT_DIR}${RESET}"
mkdir -p "$OUT_DIR/en"

log "HTML (asciidoctor + diagram)"
asciidoctor \
  -r asciidoctor-diagram \
  -a stylesheet=../theme/default-theme.css \
  -a imagesoutdir="$OUT_DIR/en/images" \
  -a outfilesuffix=.html \
  -o "$OUT_DIR/en/book.html" "$SRC"
ok "HTML → $OUT_DIR/en/book.html"

log "PDF (asciidoctor-pdf + diagram)"
asciidoctor-pdf \
  -r asciidoctor-diagram \
  -a pdf-theme="$THEME" \
  -a pdf-fontsdir="$FONTS_DIR" \
  -a imagesoutdir="$OUT_DIR/en/images" \
  -o "$OUT_DIR/en/book.pdf" "$SRC"
ok "PDF → $OUT_DIR/en/book.pdf"

log "EPUB3"
asciidoctor-epub3 \
  -a imagesoutdir="$OUT_DIR/en/images" \
  -o "$OUT_DIR/en/book.epub" "$SRC"
ok "EPUB → $OUT_DIR/en/book.epub"

printf "${GREEN}✅ Build complete:${RESET} %s (env=%s)\n" "$OUT_DIR/en/{book.html, book.pdf, book.epub}" "$ENV"
