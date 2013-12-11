#!/bin/sh

BASE=/media/Backups/common/Music

/usr/bin/perl ${BASE}/FlacArmyKnife.pl -u -T -s ${BASE}/FLACs -t ${BASE}/OGGs -v "$*"
