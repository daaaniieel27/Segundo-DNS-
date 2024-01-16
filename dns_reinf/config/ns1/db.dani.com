; dani.com
;
$TTL 86400
@ IN SOA ns1.dani.com. admin.dani.com. (
    2024011401  ; Serial
    3600        ; Refresh
    1800        ; Retry
    604800      ; Expire
    86400)      ; Minimum TTL

;

@ IN    NS      ns1.dani.com.
@ IN    NS      ns2.dani.com.
ns1.dani.com.        IN      A       192.168.57.10
ns2.dani.com.        IN      A       192.168.57.11
server1.dani.com.    IN      A       192.168.57.100
server2.dani.com.    IN      A       192.168.57.101
mail.dani.com.       IN      A       192.168.57.102
www.dani.com       CNAME     server1.dani.com