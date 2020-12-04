#!/bin/bash

# subscoper v1.4.1

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

# Create results folder
if [ ! -d "./Subscoper-Results" ]; then
	mkdir ./Subscoper-Results
fi

# Sanitize the file to remove Windows Carriage Returns
cat $targets | sed -e 's/\r//g' > ./Subscoper-Results/.targets-hosts.tmp
targets="./Subscoper-Results/.targets-hosts.tmp"


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
	if [[ -e ./Subscoper-Results/.Resolved.tmp ]]; then
		rm ./Subscoper-Results/.Resolved.tmp
	fi

	for line in $(cat $subdomains); do

		echo -ne "\r\e[KChecking: "$line
		host $line >> ./Subscoper-Results/Resolved-dirty.tmp

	done
	sleep 1
	# get rid of IPv6
	echo -e "\n\n[+] Cleaning results.."
	sed '/IPv6/d' ./Subscoper-Results/Resolved-dirty.tmp > ./Subscoper-Results/Resolved.tmp
	rm ./Subscoper-Results/Resolved-dirty.tmp > /dev/null 2>&1
	echo -e "[+] Matching results..\n"	
	sleep 2
	# counter reset
	let i=1

	IFS=$'\n'
	total=$(wc -l < ./Subscoper-Results/Resolved.tmp)

	for solved in $(cat ./Subscoper-Results/Resolved.tmp); do
			
		# increment counter
		echo -ne "\r\e[KMatching: "$i" of "$total
		
		if [[ $solved == *address* ]]; then
	    		
			ipadr=$(echo $solved | cut -d " " -f4)	

			if grep -Fq $ipadr $targets
			then
				plain=$(echo $solved | cut -d " " -f1)
				echo $plain","$ipadr >> ./Subscoper-Results/.subdomains-in-scope.tmp
			fi
		fi
		i=$((i+1))
	done

	echo -e "\n\n[+] Removing temporary files.."
	rm ./Subscoper-Results/Resolved.tmp > /dev/null 2>&1
	rm ./Subscoper-Results/.targets-hosts.tmp > /dev/null 2>&1
	sort -u ./Subscoper-Results/.subdomains-in-scope.tmp > ./Subscoper-Results/subdomains-in-scope.csv
	rm ./Subscoper-Results/.subdomains-in-scope.tmp > /dev/null 2>&1
	echo "[+] Finished"

	if [[ -e ./Subscoper-Results/subdomains-in-scope.csv ]]; then
		echo "[+] "$(wc -l < ./Subscoper-Results/subdomains-in-scope.csv)" subdomains are in scope."
		echo "[-] Results saved in Subscoper-Results folder."
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
	echo "[+] Checking Certificates for domains/subdomains..."
	echo 
	
	touch ./Subscoper-Results/.subdomains-extract.tmp
	
	count=1
	for ips in $(cat $targets); do
		echo -ne "\r\e[KChecking: "$count" of "$tarnum" ("$ips")"
		timeout 2s openssl s_client -connect $ips:443 >/dev/null 2>&1 > ./Subscoper-Results/.cert.tmp
		if grep -q "CN" ./Subscoper-Results/.cert.tmp; then
			openssl x509 -noout -text -in ./Subscoper-Results/.cert.tmp | grep DNS: | tr " " "\n" | cut -d ":" -f2 | cut -d "," -f1 >> ./Subscoper-Results/.subdomains-extract.tmp
		fi
		((count++))
	done
	
	# Cleaning file for duplicates
	rm ./Subscoper-Results/.cert.tmp > /dev/null 2>&1
	sort -u ./Subscoper-Results/.subdomains-extract.tmp | grep . > ./Subscoper-Results/.subdomains-partial-list.tmp
	rm ./Subscoper-Results/.subdomains-extract.tmp > /dev/null 2>&1
	
	# Creating list of Domains from the subdomains
	awk -F "." '{
		if ($NF =="uk" && $(NF-1) == "co")
			print $(NF-2)"."$(NF-1)"."$NF;
		else
			print $(NF-1)"."$NF;
		}' ./Subscoper-Results/.subdomains-partial-list.tmp > ./Subscoper-Results/.domains-list.tmp
	
	# Sort and unique Domains List:
	sort -u ./Subscoper-Results/.domains-list.tmp > ./Subscoper-Results/domains-list.txt
	domnum=$(wc -l < ./Subscoper-Results/domains-list.txt)
	echo -e "\n\n[+] Retrieving list of subdomains..."
	
	# if -b is provided than do sublist3r bruteforce
	touch ./Subscoper-Results/.subdomains-list-0.tmp
	if [[ $brute == true ]]
	then
	    echo "[-] Using brute-force option (this could take a while)..."
	    echo
	    i=1
	    for dom in $(cat ./Subscoper-Results/domains-list.txt); do
	    	echo -ne "\r\e[KChecking: "$i" of "$domnum
	    	sublist3r -d $dom -b -o ./Subscoper-Results/.subdomains-list-$i.tmp > /dev/null 2>&1
	    	((i++))
	    done
	else
	    echo "[-] Running passive checks on popular search engines (this can take a while)..."
	    echo
	    i=1
	    for dom in $(cat ./Subscoper-Results/domains-list.txt); do
	    	echo -ne "\r\e[KChecking: "$i" of "$domnum
	    	sublist3r -d $dom -o ./Subscoper-Results/.subdomains-list-$i.tmp > /dev/null 2>&1
	    	((i++))
	    done
	fi
	echo
	echo "[+] Consolidating results and removing temporary files..."
	# Fixing sublist3r output when <BR> is retrieved
	cat ./Subscoper-Results/.subdomains-list-*.tmp >> ./Subscoper-Results/.subdomains-partial-list.tmp
	cat ./Subscoper-Results/.subdomains-partial-list.tmp | sed -e 's/<BR>/\n/g' | sed 's/^[*]//' | sed 's/^[.]//' | grep . >> ./Subscoper-Results/.subdomains-mixed.tmp
	rm ./Subscoper-Results/.subdomains-list-*.tmp > /dev/null 2>&1
	rm ./Subscoper-Results/.subdomains-partial-list.tmp > /dev/null 2>&1
	rm ./Subscoper-Results/.domains-list.tmp > /dev/null 2>&1
	
	sort -u ./Subscoper-Results/.subdomains-mixed.tmp > ./Subscoper-Results/subdomains-list.txt
	rm ./Subscoper-Results/.subdomains-mixed.tmp > /dev/null 2>&1
	
	# Calling secondary function to match the IPs with the subdomains
	subdomains="./Subscoper-Results/subdomains-list.txt"
	
	if [[ $(wc -l < ./Subscoper-Results/subdomains-list.txt) -eq 0 ]]; then
		echo "[+] All done for you. No domains/subdomains were found."
		exit
	fi
	
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


