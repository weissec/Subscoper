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

Screenshot:
--------------------
![subscoper.sh](https://user-images.githubusercontent.com/44804367/100872575-eade2600-3499-11eb-807d-49669dfa2b7d.PNG)

