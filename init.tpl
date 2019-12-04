#!/usr/bin/env bash
echo "Hello, ${message}!" > index.html
python -m SimpleHTTPServer 2299 &