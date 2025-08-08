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

# -------------------------
# Browser: MUST be injected by CI step:
#   env:
#     PUPPETEER_EXECUTABLE_PATH: ${{ env.CHROME_PATH }}
# -------------------------
if [[ -z "${PUPPETEER_EXECUTABLE_PATH:-}" ]]; then
  err "PUPPETEER_EXECUTABLE_PATH is empty. In CI, pass it from CHROME_PATH in the build step env."
  exit 1
fi
if [[ ! -x "$PUPPETEER_EXECUTABLE_PATH" ]]; then
  err "PUPPETEER_EXECUTABLE_PATH is not an executable: $PUPPETEER_EXECUTABLE_PATH"
  exit 1
fi
log "Using browser: $PUPPETEER_EXECUTABLE_PATH"

# -------------------------
# Puppeteer config (absolute path so asciidoctor-diagram finds it)
# -------------------------
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PUPPETEER_CFG="${REPO_ROOT}/.puppeteerrc.cjs"
if [[ ! -f "$PUPPETEER_CFG" ]]; then
  warn "Puppeteer config not found at ${PUPPETEER_CFG}; proceeding without it."
  MERMAID_OPTS="--executablePath=${PUPPETEER_EXECUTABLE_PATH}"
else
  MERMAID_OPTS="--executablePath=${PUPPETEER_EXECUTABLE_PATH} --puppeteerConfigFile=${PUPPETEER_CFG}"
fi

log "${BOLD}Building (${ENV}) → ${OUT_DIR}${RESET}"
mkdir -p "$OUT_DIR/en"

# -------------------------
# HTML
# -------------------------
log "HTML (asciidoctor + diagram)"
asciidoctor \
  -r asciidoctor-diagram \
  -a mermaid-cli-opts="$MERMAID_OPTS" \
  -a source-highlighter=rouge \
  -a rouge-theme=github \
  -a stylesheet=../theme/default-theme.css \
  -a imagesoutdir="$OUT_DIR/en/images" \
  -o "$OUT_DIR/en/book.html" "$SRC"
ok "HTML → $OUT_DIR/en/book.html"

# -------------------------
# PDF
# -------------------------
log "PDF (asciidoctor-pdf + diagram)"
asciidoctor-pdf \
  -r asciidoctor-diagram \
  -a mermaid-cli-opts="$MERMAID_OPTS" \
  -a source-highlighter=rouge \
  -a pdf-theme="$THEME" \
  -a pdf-fontsdir="$FONTS_DIR" \
  -a imagesoutdir="$OUT_DIR/en/images" \
  -o "$OUT_DIR/en/book.pdf" "$SRC"
ok "PDF → $OUT_DIR/en/book.pdf"

# -------------------------
# EPUB
# -------------------------
log "EPUB3"
asciidoctor-epub3 \
  -a source-highlighter=rouge \
  -a imagesoutdir="$OUT_DIR/en/images" \
  -o "$OUT_DIR/en/book.epub" "$SRC"
ok "EPUB → $OUT_DIR/en/book.epub"

printf "${GREEN}✅ Build complete:${RESET} %s (env=%s)\n" "$OUT_DIR/en/{book.html, book.pdf, book.epub}" "$ENV"
