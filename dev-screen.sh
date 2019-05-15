#!/usr/bin/env bash

screen_cmd="screen -S maru-dev -fn"

$screen_cmd -dm -t main-edit bash
$screen_cmd -X screen -t main-cli bash
$screen_cmd -X screen -t obs-1 bash
$screen_cmd -X screen -t obs-2 bash
screen -d -R maru-dev
