# SUBSCOPER
Bash wrapper that searches a list of targets for related subdomains.

Information:
---------------
The script automatically search a provided list of hosts for SSL Certificates in order to retrieve any included domains or subdomains.
Wrapping around the Sublist3r tool, the script then retrieves a list of existing subdomains and checks which of these are pointing at the hosts provided.   
  
Alternatively, if a list of subdomains is provided (-s option), the script only verify which of these are resolving to the original hosts.  
  
Note: The -b argument can be passed to the script to use the brute-force module in sublist3r.

Requirements: sublist3r (https://github.com/aboul3la/Sublist3r.git)  
Limitation: Currently the script only checks for certificates on port 443/tcp.
Why use it: Useful during an external infrastrcuture assessment to discover web applications hosted on the servers in scope.

Screenshot:
--------------------
![subscoper.sh](https://user-images.githubusercontent.com/44804367/100872575-eade2600-3499-11eb-807d-49669dfa2b7d.PNG)
