#!/bin/bash

# subscoper v2.2 - Stable Version

# Colors
red="\e[31m"
green="\e[38;5;46m"
yellow="\e[33m"
normal="\e[0m"

# Configuration
RESULTS_DIR="./Subscoper-Results"
TEMP_DIR="$RESULTS_DIR/tmp"

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null
    fi
}

trap cleanup EXIT

banner() {
    echo -e "${green}           _                                   "
    echo -e " ___ _   _| |__  ___  ___ ___  _ __   ___ _ __ "
    echo -e "/ __| | | | '_ \/ __|/ __/ _ \| '_ \/ _ \ '__|"
    echo -e "\__ \ |_| | |_) \__ \ (_| (_) | |_) |  __/ |   "
    echo -e "|___/\__,_|_.__/|___/\___\___/| .__/ \___|_| by w315 "
    echo -e "                              |_|       ${normal}"
    echo
}

usage() {
    banner
    echo -e "${green}Usage:${normal}"
    echo "  ./subscoper.sh -t targets.txt"
    echo "  ./subscoper.sh -t targets.txt -s subdomains.txt"
    echo
    echo -e "${green}Options:${normal}"
    echo "  -t  File path to list of IP addresses/ranges (required)"
    echo "  -s  File path to subdomains file (optional)"
    echo "  -b  Enable bruteforce subdomain discovery (slow)"
    echo "  -h  Show this help message"
    echo
}

validate_ip() {
    [[ "$1" =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\/([0-9]|[1-2][0-9]|3[0-2]))?$ ]]
}

process_targets() {
    local input_file=$1
    local output_file="$TEMP_DIR/processed-targets.txt"
    local invalid=0 cidr=0 single=0
    mkdir -p "$TEMP_DIR"
    echo -e "${green}[+]${normal} Processing targets from file: $input_file"
    local total=$(wc -l < "$input_file")
    while IFS= read -r line; do
        line=$(tr -d '\r' <<< "$line" | sed -e 's/#.*//' -e 's/[[:space:]]*$//')
        [ -z "$line" ] && continue
        
        if validate_ip "$line"; then
            if [[ "$line" == */* ]]; then
                nmap -sL -n "$line" 2>/dev/null | 
                awk '/Nmap scan report/{print $NF}' | 
                grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' >> "$output_file"
                ((cidr++))
            else
                echo "$line" >> "$output_file"
                ((single++))
            fi
        else
            echo -e "${yellow}[WARNING]${normal} Invalid target: $line"
            ((invalid++))
        fi
    done < "$input_file"
    
    sort -uV "$output_file" > "${output_file}.sorted"
    mv "${output_file}.sorted" "$output_file"
    
    local unique=$(wc -l < "$output_file")
    echo -e "\n${green}Detected input:${normal}"
    echo -e "Input entries:    $total"
    echo -e "Valid targets:    $((cidr + single)) (${single} IP(s), ${cidr} CIDR range(s))"
    echo -e "Invalid entries:  $invalid"
    echo -e "Total final IPs:  $unique"
    echo
}

resolve_subdomains() {
    # Declare all variables as local
    local collected_file=$1
    local target_file="$TEMP_DIR/processed-targets.txt"
    local output_file="$RESULTS_DIR/subscoper-results.csv"
    local domain ip ips
    local totaldoms=$(wc -l < $collected_file)
    local processed=1
    mkdir -p "$RESULTS_DIR" # CHECK THIS
    : > "$output_file"  # Clear previous results
    
    echo -e "\n${green}[+]${normal} Matching domains/subdomains with provided IP addresses/ranges.."
    
    while IFS= read -r domain; do
        ips=$(dig +short "$domain" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
        for ip in $ips; do
            if grep -qFx "$ip" "$target_file"; then
                echo "$domain,$ip" >> "$output_file"
            fi
        done
        printf "\r\e[K[-] Resolving domain/subdomain: %d of %s" "$processed" "$totaldoms"
        ((processed++))
    done < "$collected_file"
    
    if [ -s "$output_file" ]; then
        sort -u "$output_file" > "${output_file}.sorted"
        mv "${output_file}.sorted" "$output_file"
        echo -e "\n[-] Found${green} $(wc -l < "$output_file") ${normal}subdomain(s) matching the IP addresses provided"
        
        # if less then 50 results, print to console

  	local line_count=$(wc -l < "$output_file")
  	if [ "$line_count" -lt 50 ]; then
  		echo
		column -s, -t $output_file
  	fi
        echo -e "\n${green}[+]${normal} Results saved to: $output_file"
    else
        echo -e "\n${yellow}[!]${normal} No matches found"
    fi
}

certificate_scan() {
    local target_file="$TEMP_DIR/processed-targets.txt"
    local output_file="$TEMP_DIR/cert-domains.txt"
    local ip domain root_domain
    local count=0 total=$(wc -l < "$target_file")
    
    # Initialize files
    mkdir -p "$TEMP_DIR"
    : > "$output_file"
    : > "$RESULTS_DIR/domains.txt"

    echo -e "${green}[+]${normal} Checking SSL certificates..."
    
    while IFS= read -r ip; do
        ((count++))
        printf "\r\e[K[-] Processing IP Address: %d/%d - %s" "$count" "$total" "$ip"
        
        # Get certificate domains
        timeout 5s openssl s_client -connect "$ip:443" </dev/null 2>/dev/null |
        openssl x509 -noout -text 2>/dev/null |
        awk -F 'DNS:|,' '/DNS:/ {for (i=2; i<=NF; i++) print $i}' |
        tr -d ' ' | sed '/^$/d' |
        while read -r domain; do
            # Save full domain to cert-domains.txt
            echo "$domain" >> "$output_file"
            
            # Extract root domain
            root_domain=$(echo "$domain" | awk -F. '{
                if (NF > 2) {
                    if ($(NF-1) ~ /^(co|com|org|net|gov|ac|edu)$/ && $NF ~ /^(uk|au|nz|jp|in)$/) {
                        print $(NF-2)"."$(NF-1)"."$NF
                    }
                    else if (NF == 4) {
                        print $(NF-2)"."$(NF-1)"."$NF
                    }
                    else {
                        print $(NF-1)"."$NF
                    }
                } else {
                    print $0
                }
            }')
            
            # Save root domain to final output
            echo "$root_domain" >> "$RESULTS_DIR/domains.txt"
        done
        
    done < "$target_file"

    # Add certificate domains to collection
    cat $output_file >> "$TEMP_DIR/collected.txt"
    # Deduplicate files
    [ -s "$output_file" ] && sort -u "$output_file" -o "$output_file"
    [ -s "$RESULTS_DIR/domains.txt" ] && sort -u "$RESULTS_DIR/domains.txt" -o "$RESULTS_DIR/domains.txt"

    echo -e "\n[-] Root domains saved to: $RESULTS_DIR/domains.txt${normal}"
}

sublist3r_scan() {
    local domain_file=$1
    local output_file="$RESULTS_DIR/subdomains.txt"
    local brute=$2  # true/false

    echo -e "\n${green}[+]${normal} Performing subdomain enumeration.."
    # Add bruteforce flag if enabled
    if [ "$brute" = "true" ]; then
        barg="-b"
        echo -e "${yellow}[Bruteforce Enabled]${normal} This might take a while"
    else
        barg=""
    fi

    # Run Sublist3r with appropriate arguments
    while IFS= read -r domain; do
    	echo "[-] Processing Domain: $domain"
        sublist3r -d "$domain" -o "$TEMP_DIR/sublist3r-results.tmp" $barg > /dev/null 2>&1 
        cat "$TEMP_DIR/sublist3r-results.tmp" >> "$output_file"
    done < "$domain_file"
   
    # Collect all domains and subdomains in a temp file
    cat $domain_file >> "$TEMP_DIR/collected.txt"
    
    echo -e "\n${green}Domain enumeration results:${normal}"
    echo -e "Root domains found:  $(wc -l < "$domain_file")"
    if [ -s "$output_file" ]; then
        sort -u "$output_file" > "${output_file}.sorted"
        mv "${output_file}.sorted" "$output_file"
        echo -e "Subdomains found:    $(wc -l < "$output_file")"
        cat $output_file >> "$TEMP_DIR/collected.txt"
    else
    echo -e "Subdomains found:    0"
    fi
}

main() {
    banner
    mkdir -p "$RESULTS_DIR" "$TEMP_DIR"
    
    # Process targets
    process_targets "$TARGETS_FILE"
    
    if [ -n "$SUBDOMAINS_FILE" ]; then
        resolve_subdomains "$SUBDOMAINS_FILE"
    else
        certificate_scan
        [ -s "$TEMP_DIR/cert-domains.txt" ] || exit 1      
        sublist3r_scan "$RESULTS_DIR/domains.txt" "$BRUTEFORCE"
        [ -s "$TEMP_DIR/sublist3r-results.tmp" ] || exit 1
        resolve_subdomains "$TEMP_DIR/collected.txt"
    fi
}

# Argument parsing
while getopts "s:t:bh" opt; do
    case $opt in
        s) SUBDOMAINS_FILE="$OPTARG" ;;
        t) TARGETS_FILE="$OPTARG" ;;
        b) BRUTEFORCE="-b" ;;
        h) usage; exit 1;;
        *) usage ;;
    esac
done

# why is usage appearing two times when selected -h?

# Validate arguments
[ -z "$TARGETS_FILE" ] && { usage; echo -e "${red}[ERROR]${normal} Target file (-t) is required!"; exit 1; }
[ ! -f "$TARGETS_FILE" ] && { usage; echo -e "${red}[ERROR]${normal} Targets file not found!"; exit 1; }
[ -n "$SUBDOMAINS_FILE" ] && [ ! -f "$SUBDOMAINS_FILE" ] && { usage; echo -e "${red}[ERROR]${normal} Subdomains file not found!"; exit 1; }

main
