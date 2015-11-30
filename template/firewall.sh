#! /bin/bash

iface='eth0'

echo "Setting up iptables firewall for $iface."

iptables -F
iptables -X

echo "Blocking all fragmented packets."
iptables -A INPUT -i $iface -f  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fragments Packets"
iptables -A INPUT -i $iface -f -j DROP

echo "Blocking FIN, URG, PSH, NULL, XMAS and RST packets."
iptables  -A INPUT -i $iface -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
iptables  -A INPUT -i $iface -p tcp --tcp-flags ALL ALL -j DROP
iptables  -A INPUT -i $iface -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "NULL Packets"
iptables  -A INPUT -i $iface -p tcp --tcp-flags ALL NONE -j DROP # NULL packets
iptables  -A INPUT -i $iface -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables  -A INPUT -i $iface -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "XMAS Packets"
iptables  -A INPUT -i $iface -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP #XMAS
iptables  -A INPUT -i $iface -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fin Packets Scan"
iptables  -A INPUT -i $iface -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans
iptables  -A INPUT -i $iface -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

echo "Allow SSH Port 3333"
iptables -A INPUT -p tcp --dport 3333 -j ACCEPT

echo "Allow HTTP Port 80"
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

echo "Allow inbound ICMP"
iptables -A INPUT -p icmp -j ACCEPT

echo "Allow 127.0.0.1"
iptables -A INPUT -s 127.0.0.1 -j ACCEPT

echo "Allow Related and Established Connections"
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $iface -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT

echo "Enable Logging of Input and Forwarding"
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

echo "Rejecting all other traffic."
iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

file='/etc/iptables.rules'
echo "Saving Firewall Rules to $file."
iptables-save > /etc/iptables.rules
