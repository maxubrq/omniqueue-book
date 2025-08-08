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

OS="$(uname -s)"

log "${BOLD}Installing Asciidoctor toolchain + Mermaid (HTML/PDF/EPUB)${RESET}"

# -------------------------
# OS-specific base deps
# -------------------------
if [[ "$OS" == "Darwin" ]]; then
  log "Detected macOS"
  if ! command -v brew &>/dev/null; then
    log "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Ruby, Node, fonts
  brew install ruby node
  # Nice to have fonts (CJK + emoji) for PDF rendering
  brew install fontforge
  brew tap homebrew/cask-fonts || true
  brew install --cask font-noto-sans-cjk-sc font-noto-sans-cjk-jp font-noto-sans-cjk-kr font-noto-color-emoji || true

  # Ensure new Ruby in PATH for current and future shells
  RUBY_PREFIX="$(brew --prefix ruby)"
  if ! echo "$PATH" | grep -q "$RUBY_PREFIX/bin"; then
    export PATH="$RUBY_PREFIX/bin:$PATH"
    SHELL_RC="$HOME/.zprofile"
    [[ -n "${ZSH_VERSION:-}" ]] || SHELL_RC="$HOME/.bash_profile"
    grep -q "$RUBY_PREFIX/bin" "$SHELL_RC" 2>/dev/null || echo "export PATH=\"$RUBY_PREFIX/bin:\$PATH\"" >> "$SHELL_RC"
  fi

elif [[ "$OS" == "Linux" ]]; then
  log "Detected Linux (Debian/Ubuntu assumed)"
  if command -v apt &>/dev/null; then
    sudo apt update
    # Ruby, build deps
    sudo apt install -y ruby ruby-dev build-essential libffi-dev zlib1g-dev
    # Node (use NodeSource to get modern Node)
    if ! command -v node &>/dev/null; then
      curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
      sudo apt install -y nodejs
    fi
    # Chromium runtime deps needed by Puppeteer/Chromium
    sudo apt install -y \
      ca-certificates fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libcairo2 libcups2 \
      libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libx11-6 libx11-xcb1 \
      libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
      libxss1 libxtst6 lsb-release xdg-utils wget unzip
    # Fonts for PDF output (Latin + CJK + emoji)
    sudo apt install -y fonts-noto fonts-noto-cjk fonts-noto-color-emoji
  else
    err "Unsupported Linux distro (no apt). Add your package manager steps manually."
    exit 1
  fi
else
  err "Unsupported OS: $OS"
  exit 1
fi

# -------------------------
# Gems (Asciidoctor stack)
# -------------------------
log "Installing Asciidoctor gems"
sudo gem install --no-document asciidoctor
sudo gem install --no-document asciidoctor-pdf
sudo gem install --no-document asciidoctor-epub3
sudo gem install --no-document asciidoctor-diagram
ok "Asciidoctor + PDF + EPUB + Diagram installed"

# -------------------------
# Mermaid CLI + Puppeteer browser
# -------------------------
log "Installing Mermaid CLI"
# Install mmdc globally (no sudo if npm prefix is user-owned; otherwise use sudo)
if npm config get prefix | grep -qE "^/usr|^/opt|^/var"; then
  # global prefix is system dir → need sudo
  sudo npm i -g @mermaid-js/mermaid-cli
else
  npm i -g @mermaid-js/mermaid-cli
fi
ok "Mermaid CLI installed"

log "Installing Chromium for Puppeteer (headless)"
# Use Puppeteer's browser manager to download a compatible Chromium
# NOTE: This installs to ~/.cache/puppeteer by default
npx --yes @puppeteer/browsers install chromium@latest
# Get the path Puppeteer will use and persist for your shells
CHROMIUM_PATH="$(npx --yes @puppeteer/browsers path chromium)"
ok "Chromium installed at: ${CHROMIUM_PATH}"

# Persist env var so Mermaid CLI / Puppeteer can find it everywhere
ENV_FILE="$HOME/.bashrc"
[[ -n "${ZSH_VERSION:-}" ]] && ENV_FILE="$HOME/.zshrc"
if ! grep -q "PUPPETEER_EXECUTABLE_PATH" "$ENV_FILE" 2>/dev/null; then
  echo "export PUPPETEER_EXECUTABLE_PATH=\"$CHROMIUM_PATH\"" >> "$ENV_FILE"
  ok "Wrote PUPPETEER_EXECUTABLE_PATH to $ENV_FILE"
fi
export PUPPETEER_EXECUTABLE_PATH="$CHROMIUM_PATH"

# -------------------------
# Sanity checks
# -------------------------
log "Sanity check: asciidoctor"
asciidoctor --version | sed 's/^/  /'
log "Sanity check: mmdc"
if ! command -v mmdc &>/dev/null; then
  err "mmdc (Mermaid CLI) not found in PATH. Ensure your npm global bin is in PATH."
  warn "Try: export PATH=\"\$(npm bin -g):\$PATH\""
else
  mmdc --version | sed 's/^/  /'
fi

ok "Setup complete"

printf "\n${BOLD}Usage:${RESET}\n"
printf "  asciidoctor -r asciidoctor-diagram file.adoc        # → HTML with diagrams\n"
printf "  asciidoctor-pdf -r asciidoctor-diagram file.adoc     # → PDF with diagrams\n"
printf "  asciidoctor-epub3 file.adoc                          # → EPUB\n\n"
printf "${YELLOW}Note:${RESET} If diagrams still fail, open a new shell (to load env) or export PUPPETEER_EXECUTABLE_PATH in your CI.\n"
