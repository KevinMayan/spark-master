#!/bin/bash

$SPARK_HOME/sbin/start-history-server.sh && jupyter lab --ip=0.0.0.0
