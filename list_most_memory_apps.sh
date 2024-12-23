#!/usr/bin/env bash

#=tools
#@list the top three apps that take up the most memory

ps aux | sort -rk 4 | head -n 4 | awk '{print $2, $4, $11}'
