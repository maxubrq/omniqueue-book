#!/usr/bin/env bash
set -e

echo "==> Installing Asciidoctor and dependencies for HTML, PDF, EPUB..."

# Detect OS
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
    echo "==> Detected macOS"
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install ruby
    echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zprofile
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

elif [[ "$OS" == "Linux" ]]; then
    echo "==> Detected Linux"
    sudo apt update
    sudo apt install -y ruby ruby-dev build-essential libffi-dev zlib1g-dev
else
    echo "Unsupported OS: $OS"
    exit 1
fi

echo "==> Installing Asciidoctor (HTML)..."
sudo gem install asciidoctor

echo "==> Installing Asciidoctor PDF (PDF)..."
sudo gem install asciidoctor-pdf

echo "==> Installing Asciidoctor EPUB3 (EPUB)..."
sudo gem install asciidoctor-epub3

echo "==> Installing Asciidoctor Diagram (optional)..."
sudo gem install asciidoctor-diagram

echo "==> Installing Puperteer (optional)..."
sudo npm -g install puppeteer

echo "==> Installing Chrome (optional)..."
sudo npx puppeteer browsers install

echo "==> Installing Mermaid CLI (optional)..."
sudo npm install -g @mermaid-js/mermaid-cli

echo "==> Setup complete!"
echo
echo "📘 Usage:"
echo "  asciidoctor yourfile.adoc             # → HTML"
echo "  asciidoctor-pdf yourfile.adoc         # → PDF"
echo "  asciidoctor-epub3 yourfile.adoc       # → EPUB"
