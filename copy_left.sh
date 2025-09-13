#!/bin/bash

extract ~/Téléchargements/firmware.zip
cp *left*.uf2 /media/$USER/NICENANO/left.uf2
rm -f *.uf2
