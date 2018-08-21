#!/bin/bash

cd /data/tiburon/bootapp
/usr/bin/starman ./boot.pl --listen :27182 --workers 10 
