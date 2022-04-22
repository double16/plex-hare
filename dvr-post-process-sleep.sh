#!/usr/bin/env bash

#
# Sleeps a random amount of time to prevent IOPS overload when transitioning time slots.
#

sleep $((35 + RANDOM % 20))

exit 0
