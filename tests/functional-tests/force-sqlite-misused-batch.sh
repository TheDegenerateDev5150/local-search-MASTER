#!/bin/bash

source helper-test-data.sh

echo "Ready, now running the test (" $XDG_DATA_HOME ")"
/usr/local/libexec/tracker-store -v 0 &
/usr/bin/env python 11-sqlite-batch-misused.py


