# SUBSCOPER
Bash wrapper that searches a list of targets for related subdomains.

Information:
---------------
The script automatically search a provided list of hosts for SSL Certificates in order to retrieve any included domains or subdomains.
Wrapping around the Sublist3r tool, the script then retrieves a list of existing subdomains and checks which of these are pointing at the hosts provided.   
  
Alternatively, if a list of subdomains is provided (-s option), the script only verify which of these are resolving to the hosts provided.  
  
Note: The -b argument can be passed to the script to use the brute-force module in sublist3r.

**Requirements:** sublist3r (https://github.com/aboul3la/Sublist3r.git)  
**Limitation:** Currently the script automatically retrieve initial domains from SSL-TLS certificates on port 443/tcp only.  
**Why use it:** Useful during an external infrastrcuture assessment to discover applications and services hosted on the servers in scope.  

### Usage
Provide a list of IP addresses/ranges:
`bash subscoper.sh -t targets.txt`

With subdomain list:
`bash subscoper.sh -t targets.txt -s subdomains.txt`

Brute-force mode (when using Sublist3r):
`bash subscoper.sh -t targets.txt -b`

Screenshot:
--------------------
![subscoper.sh](https://user-images.githubusercontent.com/44804367/100872575-eade2600-3499-11eb-807d-49669dfa2b7d.PNG)

**To Do:**
- Automatically retrieve domain names from other services and ports (HTTP,SMTP,IMAP,POP3,RDP...)
- Add a check for Virtual Hosts
- Issue: nslookup seems to miss some IPs, domains resolve to different IPs than when pinging manually, creating false results.
- Double domains issue: whe domain is like test.org.uk, or test.co.uk, the lookup is for "org.uk" (wrong results)
