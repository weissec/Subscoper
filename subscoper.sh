#!/bin/bash

# subscoper v1.1

# This script takes one input parameter, a list of hosts
# The script will scan for common ports that use SSL/TLS and retrieve the domain from the certificate
# The script will then run sublist3r for each domain and retrieve a list of subdomains
# The script will resolve the IP address for each subdomain and compare each one to the addresses in scope.
# The output for the tool is a file containing only the domains in scope and relative IP address)

# Colors:
red="\e[31m"
green="\e[38;5;46m"
normal="\e[0m"
yellow="\e[33m"



banner() {

	clear
	echo -e $green"           _                                   "
	echo -e " ___ _   _| |__  ___  ___ ___  _ __   ___ _ __ "
	echo -e "/ __| | | | '_ \/ __|/ __/ _ \| '_ \ / _ \ '__|"
	echo -e "\__ \ |_| | |_) \__ \ (_| (_) | |_) |  __/ |   "
	echo -e "|___/\__,_|_.__/|___/\___\___/| .__/ \___|_| by w315 "
	echo -e "                              |_|       "
	echo -e $normal

}

usage() {

	banner
	echo -e $green"Option 1: a list of IP addresses is provided"$normal
	echo "- Automatically checks if any domains/subdomains resolve to the IPs provided."
	echo
	echo -e $green"Option 2: a list of IP addresses and a list of subdomains are provided"$normal
	echo "- Compare the two lists and verify which subdomains are related to the IPs."
	echo
	echo -e $green"Usage:"$normal" ./subscoper.sh -t IPs.txt"
	echo "       ./subscoper.sh -s subdomains.txt -t IPs.txt"
	echo
	echo -e $green"Option:       Description:"$normal
	echo " -s           Path of file containing subdomains (optional)"
	echo " -t           Path of file containing targets (required)"
	echo " -b           Use bruteforce for subdomains discovery (optional)"
	echo " -h           Display this help message"
	echo
}

while getopts "h:s:t:b" option; do
	case "${option}" in
    		s) subdomains=${OPTARG};;
		t) targets=${OPTARG};;
		b) brute=true;;
	    	h) usage; exit;;
	    	*) usage; exit;;
 	esac
done

if [[ $targets = "" ]]; then
	usage
	exit
fi

# Check if provided files exist:
if [ ! -e $targets ]; then
	banner
	echo -e $red"[ERROR]"$normal" The "$targets" file does not exist." 
	exit
fi


havesubs() {

	# Check if provided files exist:
	if [ ! -e $subdomains ]; then
		banner
		echo -e $red"[ERROR]"$normal" The "$subdomains" file does not exist." 
		exit
	fi

	total=$(wc -l < $subdomains)

	# Run
	echo -e "[+] Translating subdomains.. ("$total" found)\n"

	# Clean up if script run and not terminate
	if [[ -e ./.Resolved.tmp ]]; then
		rm ./.Resolved.tmp
	fi

	for line in $(cat $subdomains); do

		echo -ne "\r\e[KChecking: "$line
		host $line >> .Resolved-dirty.tmp

	done
	sleep 1
	# get rid of IPv6
	echo -e "\n\n[+] Cleaning results.."
	sed '/IPv6/d' .Resolved-dirty.tmp > .Resolved.tmp
	rm .Resolved-dirty.tmp
	echo -e "[+] Matching results..\n"	
	sleep 2
	# counter reset
	let i=1

	IFS=$'\n'
	total=$(wc -l < .Resolved.tmp)

	for solved in $(cat .Resolved.tmp); do
			
		# increment counter
		echo -ne "\r\e[KMatching: "$i" of "$total
		
		if [[ $solved == *address* ]]; then
	    		
			ipadr=$(echo $solved | cut -d " " -f4)	

			if grep -Fq $ipadr $targets
			then
				plain=$(echo $solved | cut -d " " -f1)
				echo $plain" ("$ipadr")" >> Subdomains-in-Scope.txt
			fi
		fi
		i=$((i+1))
	done

	echo -e "\n\n[+] Removing temporary files.."
	rm .Resolved.tmp
	echo "[+] Finished"

	if [[ -e ./Subdomains-in-Scope.txt ]]; then
		echo "[+] "$(wc -l < Subdomains-in-Scope.txt)" subdomains are in scope."
		echo "[-] Results saved in: ./Subdomains-in-Scope.txt"
	else
		echo "[-] No subdomains found to be in scope."
	fi

}

fullrun() {

	# Checking if sublist3r is installed:
	if ! which sublist3r >/dev/null; then
    		banner
		echo -e $red"[ERROR]"$normal" Sublist3r is required for this tool to work (https://github.com/aboul3la/Sublist3r.git)"
		exit
	fi
	
	tarnum=$(wc -l < $targets)
	
	if [[ $tarnum == 0 ]]; then
		banner
		echo -e $red"[ERROR]"$normal" No valid IP addresses found."
		exit
	fi

	banner
	echo "[+] Found "$tarnum" IP Address/es."
	echo "[+] Checking X509 Certificates for domain names..."
	echo 
	for ips in $(cat $targets); do
		echo -ne "\r\e[KChecking: "$ips
		openssl s_client -connect 162.27.160.1:443 </dev/null 2>/dev/null | openssl x509 -noout -subject | awk -F. '{print $(NF-1)"."$NF}' | tr -d '[:blank:]' >> .domains-extract.tmp
	done
	# Cleaning file for duplicates
	sort -u .domains-extract.tmp > domains-list.txt
	rm .domains-extract.tmp > /dev/null 2>&1
	
	echo -e "\n\n[+] Retrieving list of subdomains..."
	# if -b is provided than do sublist3r bruteforce
	if [[ $brute == true ]]
	then
	    echo "[-] Using brute-force option (this could take a while)..."
	    i=1
	    for dom in $(cat domains-list.txt); do
	    	sublist3r -d $dom -b -o .subdomains-list-$i.tmp > /dev/null 2>&1
	    	((i++))
	    done
	else
	    echo "[-] Running passive checks on popular search engines (this can take a while)..."
	    i=1
	    for dom in $(cat domains-list.txt); do
	    	sublist3r -d $dom -o .subdomains-list-$i.tmp > /dev/null 2>&1
	    	((i++))
	    done
	fi
	
	echo "[+] Consolidating results and removing temporary files..."
	cat .subdomains-list-*.tmp >> subdomains-list.txt
	rm .subdomains-list-*.tmp > /dev/null 2>&1
	
	# Calling secondary function to match the IPs with the subdomains
	subdomains="subdomains-list.txt"
	
	havesubs
	
	echo
	echo "[+] All done for you. Thanks for using subscoper.sh!"
	
}

# Selector:
if [[ $subdomains == "" ]]; then
	fullrun
else
	banner
	havesubs
fi


