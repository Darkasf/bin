#!/bin/bash

# http://github.com/MitchWeaver/bin

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ] ; then
    echo "Usage: -get, -inc, -dec, -mute"
    exit 0
fi

if [ "$(uname)" = "Linux" ] ; then

    case "$1" in

        "-get")
            if [ -z "$(pgrep pulseaudio)" ] ; then
                # vol=$(awk -F"[][]" '/dB/ { print $2 }' $(amixer sget Master))
                vol=$(amixer get Master | grep % | awk '{print $4}' | \
                    sed -e 's/\[//' -e 's/\]//')
            else
                vol=$(amixer -D pulse sget Master | \
                    awk '/%/ {gsub(/[\[\]]/,""); print $5}')
            fi

            vol_val=$(echo $vol | sed 's/.$//')
            ;;

        "-inc")
            if [ -z "$(pgrep pulseaudio)" ] ; then
                amixer -q sset Master "$2"%+
            else
                amixer -q -D pulse sset Master "$2"%+
            fi
            ;;

        "-dec")
            if [ -z "$(pgrep pulseaudio)" ] ; then
                amixer -q sset Master "$2"%-
            else
                amixer -q -D pulse sset Master "$2"%-
            fi
            ;;

        "-mute")
            echo "Unimplemented. To do."
            exit
            ;;

    esac

# elif test mixerctl ; then
else # BSD

    case "$1" in
        "-get")
            tmp="$(mixerctl -n outputs.master)"
            vol_val=${tmp%,*}

            # BSD has a peculiarity, that its volume is actually 0-255, not 0-100
            # To get the proper percent, we will accomodate for that here.
            vol_val=$(echo $vol_val \* 0.392 | bc)
            # convert back to int
            vol_val=${vol_val%.*}

            # checks if the volume is either A: below zero
            # or B: a non-number was returned
            if [ $vol_val -lt 0 ] ; then
                vol_val=0
            elif [ $vol_val -gt 98 ] ; then
                vol_val=100
            fi

            vol=$vol_val% ;;

        "-inc")
            mixerctl -q outputs.master="+$2"
            exit ;;

        "-dec")
            mixerctl -q outputs.master="-$2"
            exit ;;

        "-mute")
            # restoring from mute
            if [ $(mixerctl -n outputs.master) -eq 0 ] ; then
                if [ -f /tmp/mutevol] ; then
                    mixerctl -q outputs.master=$(cat /tmp/mutevol)
                    rm /tmp/mutevol
                fi
            else
                echo $(mixerctl -n outputs.master) > /tmp/mutevol
                mixerctl -q outputs.master=0
            fi ;;
        esac

fi

echo "$vol_val"
