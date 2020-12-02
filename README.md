# SUBSCOPER
Bash wrapper that searches a list of targets for related subdomains.

Information:
---------------
The script automatically search SSL Certificates for a provided list of hosts and retrieve the domain specified under the X509 Subject Common Name.
Using the Sublist3r tool, the script retrieves a list of existing subdomains and checks which of these are pointing at the hosts provided. 

Alternatively, if a list of subdomains is provided (-s option), the script only verify which of these are pointing at the hosts provided.

Note: The -b argument can be passed to the script to use the brute-force module in sublist3r.

Requirements: sublist3r (https://github.com/aboul3la/Sublist3r.git)

Screenshot:
--------------------
https://user-images.githubusercontent.com/44804367/100872575-eade2600-3499-11eb-807d-49669dfa2b7d.PNG
