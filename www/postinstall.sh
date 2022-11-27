#!/bin/bash

LOGFILE="/var/log/postinstall.log"
puppet apply -l $LOGFILE --verbose /root/postinstall.pp

/bin/systemctl disable postinstall.service
