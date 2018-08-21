#!/bin/bash

cd /data/tiburon/objstor/

echo "-------------------------------------------------------------------" >> \
	/data/tiburon/objstor/minio.log
echo -n "started on "
date >> /data/tiburon/objstor/minio.log
echo >> /data/tiburon/objstor/minio.log
/data/tiburon/objstor/minio server /data/tiburon/objects/1 \
	/data/tiburon/objects/2 /data/tiburon/objects/3    \
	/data/tiburon/objects/4 /data/tiburon/objects/5    \
	/data/tiburon/objects/6 /data/tiburon/objects/7    \
	/data/tiburon/objects/8 /data/tiburon/objects/9    \
	/data/tiburon/objects/10 /data/tiburon/objects/11  \
	/data/tiburon/objects/12 >> /data/tiburon/objstor/minio.log
