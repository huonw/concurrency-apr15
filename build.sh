#!/bin/sh

rustdoc slides.md -o . --html-in-header=header.inc.html --markdown-no-toc
rustdoc intro.md -o . --html-in-header=header.inc.html --markdown-no-toc
