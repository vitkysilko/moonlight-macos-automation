#!/bin/bash
# Ukonci vsechny bezici streamy natvrdo (kill -9), bez cekani.
pkill -9 -f "Contents/MacOS/Moonlight stream"
exit 0
