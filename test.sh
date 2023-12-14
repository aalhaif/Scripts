current_order=$(networksetup -listnetworkserviceorder | grep -E '^\([0-9]+\)' | awk -F'\\) ' '{ if (index($2, " ") > 0) printf "\"%s\" ", $2; else printf "%s ", $2}')
echo $current_order