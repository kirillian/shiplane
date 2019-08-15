#!/usr/bin/env bash
# This script starts a bashttpd server

:;while [ $? -eq 0 ];do nc -lp 23480 -e bin/bashttpd ;done
