#!/bin/bash
#
for file in * 
do
echo $file
mv $file `echo $file | tr [:upper:] [:lower:]`
done
