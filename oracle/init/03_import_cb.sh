#!/bin/bash
set -e

echo "Importing CB schema..."

impdp system/oracle \
  schemas=CB \
  directory=DATA_PUMP_DIR \
  dumpfile=cb/cb.dmp \
  logfile=cb_import.log