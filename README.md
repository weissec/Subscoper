# Subscoper
Bash wrapper that finds domains/subdomains pointing to a list of given IP addresses.

Information:
---------------
The script automatically search a provided list of hosts for SSL Certificates in order to retrieve any included domains or subdomains.
Wrapping around the Sublist3r tool, the script then retrieves a list of existing subdomains and checks which of these are pointing at the hosts provided.   
  
Alternatively, if a list of subdomains is provided (-s option), the script only verify which of these are resolving to the hosts provided.  
  
Note: The -b argument can be passed to the script to use the brute-force module in sublist3r.

**Why?** Useful during an external infrastrcuture assessment to discover web applications and services hosted on a list of given IP addresses in scope.  

### Usage
Provide a list of IP addresses/ranges:
`bash subscoper.sh -t targets.txt`

With subdomain list:
`bash subscoper.sh -t targets.txt -s subdomains.txt`

Brute-force mode (when using Sublist3r):
`bash subscoper.sh -t targets.txt -b`

### Requirements
The tool requires the following dependancies:
- dig (from dnsutils)
- nmap
- openssl
- sublist3r (https://github.com/aboul3la/Sublist3r)

You can install them with:
```
sudo apt install dnsutils openssl nmap
git clone https://github.com/aboul3la/Sublist3r.git
export PATH=$PATH:/path/to/Sublist3r/
```

### Example Results
```
           _                                   
 ___ _   _| |__  ___  ___ ___  _ __   ___ _ __ 
/ __| | | | '_ \/ __|/ __/ _ \| '_ \/ _ \ '__|
\__ \ |_| | |_) \__ \ (_| (_) | |_) |  __/ |   
|___/\__,_|_.__/|___/\___\___/| .__/ \___|_| by w315 
                              |_|       

[+] Processing targets from file: targets.txt

Detected input:
Input entries:    2
Valid targets:    2 (2 IP(s), 0 CIDR range(s))
Invalid entries:  0
Total final IPs:  2

[+] Checking SSL certificates...
[-] Processing IP Address: 2/2 - 10.10.10.2
[-] Root domains saved to: ./Subscoper-Results/domains.txt

[+] Performing subdomain enumeration..
[-] Processing Domain: domain.co.uk
[-] Processing Domain: domain.com

Domain enumeration results:
Root domains found:  2
Subdomains found:    32

[+] Matching domains/subdomains with provided IP addresses/ranges..
[-] Resolving domain/subdomain: 34 of 34
[-] Found 2 subdomain(s) matching the IP addresses provided
subdomain.domain.co.uk              10.10.10.1
subdomain.domain.com                10.10.10.2

[+] Results saved to: ./Subscoper-Results/subscoper-results.csv
```
