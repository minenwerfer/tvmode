#!/bin/sh
# João G. Santos (ringeringeraja)

target_hdmi_res="800x600"
target_pa_profile="output:hdmi-stereo"
poweroff_command="doas poweroff"

exec 3>&1 3>&2 >>~/.tvmodelog

function log() {
  echo -e "[*] $1"
  echo -e "\t\$ $2"
  eval "$2"

  [ "$3" != "file" ] && {
    log "$1" "$2" 'file' >&3
    return 0
  }
}

function watch() {
  function is_disconnected() {
    xrandr | grep -qi 'hdmi-1 disconnected'
  }

  while true; do
    [ is_disconnected ] && {
      sleep 20
      is_disconnected && $poweroff_command
    }

    sleep 5
  done
}

current_dpms_status=$(xset q | grep -qi 'dpms is enabled')
current_hdmi_res=$(xrandr | awk '/HDMI-1/ { print $3; }')

current_pa_card=$(pactl list cards | awk -F ': ' '/Name/ { print $2; }')
current_pa_profile=$(pactl list cards | awk -F': ' '/Active Profile/ { print $2; }')

[ $current_dpms_status ] && {
  log \
    "disabling DPMS" \
    "xset -dpms s off"
}

[ $current_hdmi_res != "${target_hdmi_res+0+0}" ] && {
  log \
    "configuring display" \
    "xrandr --output HDMI-1 --left-of eDP-1 -r $target_hdmi_res"
}

[ $current_pa_profile != $target_pa_profile ] && {
  log \
    "configuring audio output" \
    "pacmd set-card-profile $current_pa_card $target_pa_profile"
}

watch
