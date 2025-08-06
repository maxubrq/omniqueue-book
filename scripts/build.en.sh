#!/bin/bash
set -e

asciidoctor -o docs/en/book.html ./en/book.adoc
asciidoctor-pdf \
  -a pdf-theme=./theme/oreilly-theme.yml \
  -a pdf-fontsdir=./theme/fonts \
  -o docs/en/book.pdf ./en/book.adoc
asciidoctor-epub3 -o docs/en/book.epub ./en/book.adoc

echo "✅ Build complete: docs/en/{book.html, book.pdf, book.epub}"