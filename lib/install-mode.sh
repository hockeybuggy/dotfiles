#!/usr/bin/env sh

install_mode_is_valid() {
    case "$1" in
        minimal|work|personal) return 0 ;;
        *) return 1 ;;
    esac
}

install_mode_has() {
    mode=$1
    capability=$2

    case "$capability" in
        core)
            install_mode_is_valid "$mode"
            ;;
        development|agents|workstation)
            case "$mode" in
                work|personal) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        personal)
            [ "$mode" = personal ]
            ;;
        *)
            return 1
            ;;
    esac
}

install_mode_usage() {
    echo "Usage: $1 (--minimal | --work | --personal)"
}
