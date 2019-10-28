#!/bin/bash

sleep 2
chmod +x $RB_SCRIP_PATH
. $RB_SCRIP_PATH

apachectl -D FOREGROUND
