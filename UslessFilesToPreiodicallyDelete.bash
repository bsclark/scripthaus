#!/bin/bash
#
find . -name _THUMBNAILS -print

for file in `find . -name _THUMBNAILS -print`; do rm -rf $file; done

for file in `find . -name THUMBS.DB -print`; do rm $file; done

