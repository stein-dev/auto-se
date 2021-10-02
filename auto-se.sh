#!/bin/bash

vnic="tap0"
dnic="wlp2s0"
gateway="192.168.1.1"

###########################################

regex='^[0-9]+$'

loading() {
    printf "\033c"
    ./vpnclient start | echo "Loading..."
    sleep 1
}

pause() {
  read -p "[Press enter to continue]" fackEnterKey
}

dconn() {
    printf "\033c"
    # sudo dhclient -r vpn_rr
    # service network-manager restart
    # service network-manager restart
    ./vpnclient stop | echo "Disconnecting..."
    echo "Done."
    pause
}

routes() {
    #1 - se ip
    echo "Getting IP..."
    dhclient vpn_$vnic
    echo "Routing IP..."
    ip route add $1 via $gateway dev $dnic proto static
    echo "Done."
}

conn() {
    printf "\033c"

    arr_account=($( ./vpncmd /client localhost /cmd accountlist | awk -F '|' '/^VPN Connection Setting Name/{print $2}'))
    arr_ip=($( ./vpncmd /client localhost /cmd accountlist | awk -F '[|:]' '/^VPN Server Hostname/{print $2}'))
    
    echo "Connecting to: [$choice * ${arr_account[$choice]} * ${arr_ip[$choice]}]"
    ./vpncmd /client localhost /cmd accountconnect ${arr_account[$choice]} | echo "..."
    routes ${arr_ip[$choice]}
    pause
}

deleteaccount() {
    loading
    printf "\033c"
    
    arr_account=($( ./vpncmd /client localhost /cmd accountlist | awk -F '|' '/^VPN Connection Setting Name/{print $2}'))
    arr_ip=($( ./vpncmd /client localhost /cmd accountlist | awk -F '[|:]' '/^VPN Server Hostname/{print $2}'))
    arr_status=($( ./vpncmd /client localhost /cmd accountlist | awk -F '[|]' '/^Status/{print $2}'))
    arr_count=${#arr_account[@]}

    echo "---------------------------------------------"
    echo "|             DELETE ACCOUNT                |"
    echo "---------------------------------------------"
    printf "%-4s %-10s %-18s %-10s \n" "#" "Name" "Server IP" "Status"
    echo   "---------------------------------------------"
    
    for ((i=0;i<=$arr_count-1;i++)); 
    do 
        printf "%-4s %-10s %-18s %-10s \n" "$i" "${arr_account[$i]}" "${arr_ip[$i]}" "${arr_status[$i]}"
    done  

    echo "---------------------------------------------"

    read -p "Enter choice: " choice
    if [[ -z $choice ]]; then
        echo "Error." && sleep 1
    elif [[ $choice > $arr_account || $choice < 0 ]]; then
        echo "Error." && sleep 1
    elif [[ ${arr_status[$choice]} = "Connected" || ${arr_status[$choice]} = "Connecting" ]]; then
        echo "Disconnect current session." && sleep 1
    else
        printf "\033c"
        echo "Deleting account: [$choice * ${arr_account[$choice]} * ${arr_ip[$choice]}]" 
        
        ./vpncmd /client localhost /cmd accountdelete ${arr_account[$choice]} | echo "Account successfully deleted."
        pause
    fi
    
}

createaccount() {
    loading
    printf "\033c"

    echo "====================================="
    echo "+          CREATE ACCOUNT           +"
    echo "====================================="
    read -p "VPN Name: " vname
    read -p "VPN Server Hostname/IP: " vip
    read -p "VPN Server Port: " vport
    read -p "VPN Hub Name: " vhub
    read -p "VPN Username: " vusername
    read -p "[1]Anonymous [2]Standard : " vauth
    if [ $vauth = 1 ]
    then
        printf "\033c"
        echo "Creating account"
        ./vpncmd /client localhost /cmd accountcreate $vname /server:$vip:$vport /hub:$vhub /username:$vusername /nicname:$vnic | echo "..."
        
        ./vpncmd /client localhost /cmd accountanonymousset $vname | echo "..."
        
        echo "Done."
        pause
    elif [ $vauth = 2 ]
    then
        read -p "VPN Password: " vpassword
        printf "\033c"
        echo "Creating account"
        ./vpncmd /client localhost /cmd accountcreate $vname /server:$vip:$vport /hub:$vhub /username:$vusername /nicname:$vnic | echo "..."
        ./vpncmd /client localhost /cmd accountpasswordset $vname /password:$vpassword /type:standard | echo "..."
        
        echo "Done."
        pause
    else
        echo "Something's wrong. I can feel it."
        pause
    fi           
}

niclist() {
    loading
    printf "\033c"

    arr_nicname=($( ./vpncmd /client localhost /cmd niclist | awk -F '|' '/^Virtual Network Adapter Name/{print $2}'))
    arr_nicstatus=($( ./vpncmd /client localhost /cmd niclist | awk -F '|' '/^Status/{print $2}'))
    arr_count=${#arr_nicname[@]}

    echo "====================================="
    printf "%-4s %-4s %-12s %-12s %-1s \n" "+" "#" "ADAPTER" "STATUS" "+"
    echo "====================================="

    for ((i=0;i<=$arr_count-1;i++)); 
    do 
        printf "%-4s %-4s %-12s %-12s %-1s \n" "+" "$i" "${arr_nicname[$i]}" "${arr_nicstatus[$i]}"  "+" 
    done

    echo "====================================="
    printf "\n"
    pause
}

serverlist() {
    loading
    printf "\033c"

    arr_account=($( ./vpncmd /client localhost /cmd accountlist | awk -F '|' '/^VPN Connection Setting Name/{print $2}'))
    arr_ip=($( ./vpncmd /client localhost /cmd accountlist | awk -F '[|:]' '/^VPN Server Hostname/{print $2}'))
    arr_status=($( ./vpncmd /client localhost /cmd accountlist | awk -F '[|]' '/^Status/{print $2}'))
    arr_vhub=($( ./vpncmd /client localhost /cmd accountlist | awk -F '[|]' '/^Virtual Hub/{print $2}'))
    arr_count=${#arr_account[@]}

    echo "=================================================================="
    printf "%-4s %-4s %-10s %-18s %-10s %-13s %-1s \n" "+" "#" "NAME" "SERVER IP" "STATUS" "HUB" "+"
    echo "=================================================================="
    
    for ((i=0;i<=$arr_count-1;i++)); 
    do 
        printf "%-4s %-4s %-10s %-18s %-10s %-13s %-1s \n" "+" "$i" "${arr_account[$i]}" "${arr_ip[$i]}" "${arr_status[$i]}" "${arr_vhub[$i]}" "+"
    done  

    echo "=================================================================="
    echo "+             >>>>>>>>>>>> SERVER LIST <<<<<<<<<<<<              +"
    echo "=================================================================="

	read -p "Enter choice: " choice
    if [[ -z $choice ]]
    then
        echo "Error." && sleep 1
    elif [[ $choice > $arr_account || $choice < 0 ]]
    then
        echo "Error." && sleep 1
    elif [[ ${arr_status[$choice]} = "Connected" || ${arr_status[$choice]} = "Connecting" ]]
    then
        echo "Disconnect current session." && sleep 1
    else
        conn
    fi
}

option() {
	read -p "Enter choice: " choice
	case $choice in
		1) serverlist;;
		2) dconn;;	
        3) createaccount;;
        4) deleteaccount;;
        5) niclist;;
		*) echo "Wooops! In earth, we called this error." && sleep 2
	esac
}

semenu() {
    printf "\033c"
    echo "============================================="
    echo "+        AUTO-SOFTETHER @ pigscanfly        +"
    echo "============================================="
    printf "%-12s %-30s %-1s \n" "+" "1. Server List" "+"
    printf "%-12s %-30s %-1s \n" "+" "2. Disconnect" "+"
    printf "%-12s %-30s %-1s \n" "+" "3. Create Account" "+"
    printf "%-12s %-30s %-1s \n" "+" "4. Delete Account" "+"
    printf "%-12s %-30s %-1s \n" "+" "5. Adapter List" "+"
    printf "%-12s %-30s %-1s \n" "+" "6. Create Adapter" "+"
    printf "%-12s %-30s %-1s \n" "+" "7. Delete Adapter" "+"
    printf "%-12s %-30s %-1s \n" "+" "8. Exit" "+"
    echo "============================================="
    option
}

while true
do
    semenu
done


