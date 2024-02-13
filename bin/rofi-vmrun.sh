#!/usr/bin/bash
# script to list and start selected vm with rofi / dmenu
#
# Bindings
#
# enter: run vm and open virt-manager
# alt+o: open virt-manager
# alt+r: run or stop vm (toggle)
#
#
## config
# display=:0

run-or-stop() {
    if [ "$2" == "running" ]; then
        notify-send "shutting down vm: $1"
        virsh shutdown $dom
    elif [ "$2" == "off" ]; then
        notify-send "starting vm: $1"
        virsh start $dom
    fi
}

show-window() {
    virt-manager --show-domain-console $1 -c qemu:///system
    notify-send "virt-manager opened"
}

handle-vm() {
    read dom state <<<"$1"
    # dom=$1
    if [ "$(virsh net-info default | grep Active | awk '{print $2}')" == "no" ]; then
        notify-send "starting virtual network"
        virsh net-start default
    fi

    case "$2" in
    0) # run and open
        if [ "$state" == "off" ]; then
            run-or-stop $dom $state
        fi
        show-window $dom

        ;;
    10) # run or stop
        run-or-stop $dom $state
        ;;
    11) #open
        show-window $dom
        ;;
    esac

}

selected_line=$1

if [ -z "$selected_line" ]; then
    selected_line=$(virsh list --all |
        awk 'NF && NR>=3 {printf "%-10s\t%s\n", $2, $NF}' |
        rofi -dmenu -p "select vm" -kb-custom-1 "Alt+r" -kb-custom-2 "Alt+o")
fi

rofi_exit=$?

if [ -z "$selected_line" ]; then
    exit
fi

handle-vm "$selected_line" $rofi_exit >/dev/null 2>1
