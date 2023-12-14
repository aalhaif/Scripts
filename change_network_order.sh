#!/bin/zsh

get_current_interface() {
    # Get the current active network service (interface)
    networksetup -listnetworkserviceorder | awk -F'\\) ' '/\(.*\)/ {print $2}' | grep -v "denotes that a network service is disabled" | head -n 1
}

change_service_order() {
    local selected_interface=$1

    # Get the current service order
    local current_order=$(networksetup -listnetworkserviceorder | grep -E '^\([0-9]+\)' | awk -F'\\) ' '{print $2}')

    # Remove any duplicate occurrences of the selected interface
    current_order=$(echo $current_order | tr ' ' '\n' | awk '!a[$0]++' | grep -v $selected_interface | tr '\n' ' ')

    # If the selected interface is not already at the top, change the order
    if [[ $selected_interface != $current_order ]]; then
        echo "Changing service order..."
        networksetup -ordernetworkservices "$selected_interface" $current_order
        echo "Service order updated!"
        echo "New service order: $selected_interface $current_order"
    else
        echo "Selected interface is already at the top. No changes needed."
    fi
}

select_interface() {
    PS3="Select the network interface: "
    options=($(networksetup -listnetworkserviceorder | grep -E '^\([0-9]+\)' | awk -F'\\) ' '{print $2}' | grep -v "denotes that a network service is disabled"))
    options+=("Quit")
    select choice in "${options[@]}"; do
        case $choice in
            "Quit")
                echo "Quitting..."
                exit 0
                ;;
            *) 
                selected_interface="$choice"
                break
                ;;
        esac
    done

    change_service_order "$selected_interface"
}

main() {
    current_interface=$(get_current_interface)
    echo "Current active network service: $current_interface"

    select_interface
}

main
