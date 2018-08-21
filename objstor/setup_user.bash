#!/bin/bash

OBJDIR=/data/tiburon/objects
mkdir -p ${OBJDIR}
useradd -m minio -d /data/tiburon/objstor
for i in 1..12; do 
 mkdir -p ${OBJDIR}/$i
done
chown -R minio ${OBJDIR}
