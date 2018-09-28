#!/bin/bash

find ../ -name ".DS_Store" -depth -exec rm {} \;

echo "Cleaning..."
make clean

rm -rf obj
rm -rf packages
rm -rf .theos
rm -rf alwaysremindmepref/.theos
echo "Cleaning done."

echo "Building..."
# FINALPACKAGE=1
make package install
echo "Building done."
