#!/bin/bash

while true
do
 read -r -p "Are You Sure? [Y/n] " input
 
 case $input in
 [yY][eE][sS]|[yY])
     exit 0
 ;;
 [nN][oO]|[nN])
     exit 1
 ;;
 *)
 echo "Invalid input..."
 ;;
 esac
done
