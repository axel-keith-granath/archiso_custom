#!/bin/bash
clear
echo "############################################################"
echo "###      Welcome to the Custom Persistent Arch ISO       ###"
echo "############################################################"
loadkeys i386/qwertz/fr_CH.map.gz
fastfetch
lsblk -f
ip a