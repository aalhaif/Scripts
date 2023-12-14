#!/bin/zsh

get_current_interface() {
    # Get the current active network service (interface)
    networksetup -listnetworkserviceorder | awk -F'\\) ' '/\(.*\)/ {print $2}' | grep -v "denotes that a network service is disabled" | head -n 1
}

change_service_order() {
    local selected_interface=$1

    # Get the current service order
    local current_order_string=$(networksetup -listnetworkserviceorder | grep -E '^\([0-9]+\)' | awk -F'\\) ' '{print $2}')

    # Remove any duplicate occurrences of the selected interface
    current_order_string=$(echo "$current_order_string" | awk '!a[$0]++' | grep -v "$selected_interface")

    # Convert the current order string into an array
    IFS=$'\n' read -rd '' -a current_order <<<"$current_order_string"

    # If the selected interface is not already at the top, change the order
    if [[ $selected_interface != ${current_order[0]} ]]; then
        echo "Changing service order..."
        networksetup -ordernetworkservices "$selected_interface" "${current_order[@]}"
        echo "Service order updated!"
        echo "New service order: $selected_interface ${current_order[*]}"
    fi
}

select_interface() {
    # Get the list of network services
    local network_services=$(networksetup -listnetworkserviceorder | grep -E '^\([0-9]+\)' | awk -F'\\) ' '{print $2}')

    # Convert the list of network services into an array
    IFS=$'\n' read -rd '' -a network_services_array <<<"$network_services"

    # Generate the options
    echo "Please select a network interface:"
    for i in "${!network_services_array[@]}"; do
        echo "$((i+1))) ${network_services_array[i]}"
    done
    echo "$(( ${#network_services_array[@]} + 1 ))) Quit"

    # Get the user's selection
    read -p "Enter your choice: " choice

    # Check if the user's input is a number
    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a number."
        select_interface
    # Validate the user's selection
    elif ((choice < 1 || choice > ${#network_services_array[@]} + 1)); then
        echo "Invalid choice. Please try again."
        select_interface
    elif ((choice == ${#network_services_array[@]} + 1)); then
        echo "Exiting..."
        exit 0
    else
        # Return the selected network service
        selected_interface="${network_services_array[$((choice-1))]}"
        # Check if the selected interface is already at the top of the list
        if [ "$selected_interface" == "${network_services_array[0]}" ]; then
            echo "$selected_interface is already at the top of the list."
            exit 0
        else
        change_service_order "$selected_interface"
        fi
    fi
}

main() {
    current_interface=$(get_current_interface)
    echo "Current active network service: $current_interface"

    select_interface
}

main