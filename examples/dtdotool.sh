#!/bin/bash

# Copyright (c) 2019, Craig P Hicks
# content licensed as CC BY-NC-SA
# CC BY-NC-SA details at https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode

# This program depends upon 'xdotool' installed as  Ubuntu 18.04 managed package
# xdotool project source can be found at:
#    https://github.com/jordansissel/xdotool
#    https://www.semicomplete.com/projects/xdotool/
# xdotool license:
#     ©Copyright 2006-2019 Jordan Sissel - Content licensed as CC BY-NC-SA
#     https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode


# This program manipulates the desktops as atomic elements of an array.
# E.g., swapping element order, inserting and deleting empty elements.
# It works through the 'xdotool' interface.


window_has_desktop(){
    xdotool get_desktop_for_window $1  >/dev/null 2>&1
}

swaprelative(){
	nbr=$1
    ndt=$(xdotool get_num_desktops)
    if [[ $ndt -lt 2 ]] ; then return 0 ; fi
    adt=$(xdotool get_desktop)
    #bdt=$(( adt == 0 ? ndt-1 : adt-1 ))
	bdt=$((( adt + ndt + nbr) % ndt ))
	if [[ $bdt == $adt ]] ; then return 0; fi
	if [[ $bdt -lt 0 ]] ; then
		echo "relative neighbor value $nbr is out of bounds"
		return 1;
	fi
    xdotool search '.*' | while read w ; do
        if ! window_has_desktop $w ; then continue; fi
        wdt=$(xdotool get_desktop_for_window $w)
        if [[ $wdt -eq $adt ]] ; then
            xdotool set_desktop_for_window $w $bdt
        elif [[ $wdt -eq $bdt ]] ; then
            xdotool set_desktop_for_window $w $adt
        fi
    done
    xdotool set_desktop $bdt
}

insertnewdt(){
    ndt=$(xdotool get_num_desktops)
    xdotool set_num_desktops $((ndt+1))
    adt=$(xdotool get_desktop)
    xdotool search '.*' | while read w ; do
        if ! window_has_desktop $w ; then continue; fi
        wdt=$(xdotool get_desktop_for_window $w)
        if [[ $wdt -ge $adt ]] ; then
            xdotool set_desktop_for_window $w $((wdt+1))
        fi
    done
}
    
pushnewdt(){
    ndt=$(xdotool get_num_desktops)
    xdotool set_num_desktops $((ndt+1))
    xdotool set_desktop $ndt
}

rmempty(){
    ndt=$(xdotool get_num_desktops)
    adt=$(xdotool get_desktop)
    count=( $(for i in $(seq 1 $ndt); do echo 0; done) )
    # loop input must redirected to allow count to be manipilated in top scope
    while read w ; do
        if ! window_has_desktop $w ; then continue; fi
        wdt=$(xdotool get_desktop_for_window $w)
        count[$wdt]=$((${count[$wdt]}+1))
    done < <(xdotool search '.*' 2>/dev/null)
    #echo "raw count : ${count[*]}" # debug
    nz=0
    for i in ${!count[@]} ; do
        #for i in $(seq 0 $((ndt-1))); do
        if [[ count[$i] -eq 0 ]] ; then
            nz=$((nz+1))
            count[$i]=-1
        else
            count[$i]=$((i-$nz))
        fi
    done
    #echo "count -> position : ${count[*]}" # debug
    xdotool search '.*' 2>/dev/null | while read w ; do
        if ! window_has_desktop $w ; then continue; fi
        wdt=$(xdotool get_desktop_for_window $w)
        #echo "move window from desktop $wdt to ${count[$wdt]}"
        xdotool set_desktop_for_window $w ${count[$wdt]}
    done
	xdotool set_num_desktops $((ndt-nz))
	if [[ ${count[$adt]} -ge 0 ]] ; then 
		xdotool set_desktop ${count[$adt]}
	fi
}

help(){
cat <<EOF
Usage:
    dtdotool <command>

where <command> is one of
   swaprelative (or S) <delta>
   swapup ( or su)
   swapdown (or sd)
   insertnewdt (or i)
   pushnewdt (or p)
   rmempty (or r)

Desscription
    swaprelative <delta>
        Exchange position of *current* desktop with the one given by
        ((current desktop) + <delta>) modulus (numbr of desktops).
        Note: Implemenation requies that <delta> is greter than 
        -(number of desktops)
    swapup
        same as "swaprelative -1"
    swapdown
        same as "swaprelative 1"
    insertnewdt
        Insert a new empty desktop above the *current* desktop.
    pushnewdt
        Append a new empty desktop to bottom.
    rmempty
        Remove all empty desktops.
EOF
}


case $1 in
    swaprelative | sr )
        swaprelative $2
        ;;
    swapup | su )
        swaprelative -1
        ;;
    swapdown | sd )
        swaprelative 1
        ;;
    insertnewdt | i )
        insertnewdt
        ;;
    pushnewdt | p )
        pushnewdt
        ;;
    rmempty | r )
        rmempty
        ;;
    help | h | * )
        help
esac
