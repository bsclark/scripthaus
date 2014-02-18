#!/bin/bash
#
find / \( -perm -04000 -o -perm -02000 \) -type f -exec ls -l {} \;
