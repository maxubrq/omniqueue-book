#!/bin/bash
set -e

asciidoctor -o docs/vi/book.html ./vi/book.adoc
asciidoctor-pdf \
  -a pdf-theme=./theme/orstyle-theme.yml \
  -a pdf-fontsdir=./fonts \
  -o docs/vi/book.pdf ./vi/book.adoc
asciidoctor-epub3 -o docs/vi/book.epub ./vi/book.adoc

echo "✅ Build complete: docs/vi/{book.html, book.pdf, book.epub}"