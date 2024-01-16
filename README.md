# DNS PRACTICE REINFORCEMENT # 

## INTRODUCTION ##

Before starting the practice, it is necessary to set the static ip addresses of the servers and install the bind9 service on both of them.

The objective of this practice is to create two machines that will act as DNS servers of an imaginary domain called "dani.com". We will use **Vagrant** to automate the task of creating and configuring the machines. 

The domain will consist of four servers (in my case the practice is finished with the ip's of tierra and venus swapped):

|        Servers          |       IP       |
|----------------------|----------------|
| ns1.dani.com | 192.168.57.10 |
| ns2.dani.com    | 192.168.57.11 |
| server1.dani.com   | 192.168.57.100 |
| server2.dani.com    | 192.168.57.101 |
| mail.dani.com    | 192.168.57.102 |

- **ns1** will be the master nameserver, and will be authoritative of both zones, forward and reverse.
- **ns2** will be the slave nameserver.
- **mail** will be the mail server.

## CONFIGURATION ## 

### NAMED CONFIGURATION ###

First, we will set earth and venus as default DNS servers.
To do this we edit the `/etc/resolv.conf` file on both servers.

```conf
nameserver 192.168.57.10
nameserver 192.168.57.11
```

#### named.conf.options config ####

*(All the configuration files of bind are located in `/etc/bind/`)* 

We start by editing the `named.conf.options` file. In this we will establish configurations such as, trusted networks, forwarders, activate or deactivate the recursion, etc.
Following the indications of the practice we establish the following options (in both servers):

```conf
acl confiables {
        192.168.57.0/24;
        127.0.0.0/8;
};


options {
        directory "/var/lib/bind";

         forwarders {
                1.1.1.1;
        };

        allow-transfer { 192.168.57.11; };
        listen-on port 53 { 192.168.57.10; };

        recursion yes;
        allow-recursion { confiables; };

        dnssec-validation yes;

        // listen-on-v6 { any; };
};

```
- Explanation of the chosen options:
    - `acl`: we configure our trusted networks.
    - `forwarders`: we set 1.1.1.1 for non-authoritative requests.
    - `allow-transfer { trusted; }`: we allow the transfer from our trusted network. This will allow the transfer of the zone between the master and the slave.
    - `recursion`: we allow the recursion from the trusted network.


#### named.conf.local ####

In this file we define the zones, here where we indicate where the files of each zone will be stored. In addition, we set the role of the server (master or slave). 

**Master:**

```conf
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "dani.com" {
    type master;
    file "/var/lib/bind/db.dani.com";
};

zone "57.168.192.in-addr.arpa" {
    type master;
    file "/var/lib/bind/57.168.192.db";
};

```

**Slave:**

```conf
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "dani.com" {
    type slave;
    file "/var/lib/bind/db.dani.com";
    masters { 192.168.57.10; };  # Dirección IP de ns1
};

zone "57.168.192.in-addr.arpa" {
    type slave;
    file "/var/lib/bind/57.168.192.db";
    masters { 192.168.57.10; };  
};
```

Now we can restart the named service to apply the changes.

* (To test that the configuration is correct we can use the command: `# named-checkconf [file]` for config files, and `# named-checkzone [zone] [file]` for zone files)


### ZONES CONFIGURATION ###

#### FORWARD ZONE (/var/lib/bind/db.dani.com) ####

As indicated in the `named.conf.local` file, we will store the zone configuration file in `/var/lib/bind/db.dani.com`. *(we can use the file `/etc/bind/db.empty` to copy it as a template)*.

To follow the indications of the practice, the file should look like this: 

```conf;
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
```
*(we used absolute paths in this case)*

- Set negative cache TTL to 2h (7200s)
- Set ns1 and ns2 as the domain name servers
- Set mail as the domain mail server 
- Set the corresponding aliases to name servers and mail server

#### REVERSE ZONE (/var/lib/57.168.192.db) ####

```conf
;57.168.192
;
$TTL 86400
@       IN      SOA     ns1.dani.com. admin.dani.com. (
                            2024011401  ; Serial
                            3600        ; Refresh
                            1800        ; Retry
                            604800      ; Expire
                            86400)      ; Minimum TTL

;

@       IN      NS      ns1.dani.com.
@       IN      NS      ns2.dani.com.
10      IN      PTR     ns1.dani.com.
11      IN      PTR     ns2.dani.com.
100     IN      PTR     server1.dani.com.
101     IN      PTR     server2.dani.com.
102     IN      PTR     mail.dani.com.
```
*(we used relative paths in this case)*

- Set negative cache TTL to 2h (7200s)
- Set the name servers (ns1 and ns2)
- Set the corresponding IP to name translations
  
#### CHECKS ####
Once we have finished the practice we check it using the dig command:

```

vagrant@ns2:~$ nslookup server1.dani.com
Server:         192.168.57.10
Address:        192.168.57.10#53

Name:   server1.dani.com
Address: 192.168.57.100

vagrant@ns2:~$ nslookup server2.dani.com
Server:         192.168.57.10
Address:        192.168.57.10#53

Name:   server2.dani.com
Address: 192.168.57.101

vagrant@ns2:~$ nslookup mail.dani.com
Server:         192.168.57.10
Address:        192.168.57.10#53

Name:   mail.dani.com
Address: 192.168.57.102


vagrant@ns2:~$ nslookup 192.168.57.10
10.57.168.192.in-addr.arpa      name = ns1.dani.com.

vagrant@ns2:~$ nslookup 192.168.57.11
11.57.168.192.in-addr.arpa      name = ns2.dani.com.

vagrant@ns2:~$ nslookup 192.168.57.100
100.57.168.192.in-addr.arpa     name = server1.dani.com.

vagrant@ns2:~$ nslookup 192.168.57.101
101.57.168.192.in-addr.arpa     name = server2.dani.com.

vagrant@ns2:~$ nslookup 192.168.57.102
102.57.168.192.in-addr.arpa     name = mail.dani.com.

vagrant@ns2:~$ dig server1.dani.com

; <<>> DiG 9.16.44-Debian <<>> server1.dani.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29698
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: e95645a365e9abb60100000065a6ccf53acf1ad00d3305e2 (good)
;; QUESTION SECTION:
;server1.dani.com.              IN      A

;; ANSWER SECTION:
server1.dani.com.       86400   IN      A       192.168.57.100

;; Query time: 3 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:37:41 UTC 2024
;; MSG SIZE  rcvd: 89

vagrant@ns2:~$ dig server2.dani.com

; <<>> DiG 9.16.44-Debian <<>> server2.dani.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 313
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: b5af3378819e1b870100000065a6cd19796762d74cb5684c (good)
;; QUESTION SECTION:
;server2.dani.com.              IN      A

;; ANSWER SECTION:
server2.dani.com.       86400   IN      A       192.168.57.101

;; Query time: 3 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:38:17 UTC 2024
;; MSG SIZE  rcvd: 89

vagrant@ns2:~$ dig mail.dani.com

; <<>> DiG 9.16.44-Debian <<>> mail.dani.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63547
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: a2cf2ade0e63a5bd0100000065a6cd36703188e9c0e7f14f (good)
;; QUESTION SECTION:
;mail.dani.com.                 IN      A

;; ANSWER SECTION:
mail.dani.com.          86400   IN      A       192.168.57.102

;; Query time: 11 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:38:46 UTC 2024
;; MSG SIZE  rcvd: 86

vagrant@ns2:~$ dig www.dani.com

; <<>> DiG 9.16.44-Debian <<>> www.dani.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 16298
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: c9544609db167cb90100000065a6cd4c579d2f97dd4b7885 (good)
;; QUESTION SECTION:
;www.dani.com.                  IN      A

;; AUTHORITY SECTION:
dani.com.               86400   IN      SOA     ns1.dani.com. admin.dani.com. 2024011401 3600 1800 604800 86400

;; Query time: 7 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:39:08 UTC 2024
;; MSG SIZE  rcvd: 115

vagrant@ns2:~$ dig -x 192.168.57.10

; <<>> DiG 9.16.44-Debian <<>> -x 192.168.57.10
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 10302
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: aea6eef1aba67b6e0100000065a6cdb2e34089eff7d5def9 (good)
;; QUESTION SECTION:
;10.57.168.192.in-addr.arpa.    IN      PTR

;; ANSWER SECTION:
10.57.168.192.in-addr.arpa. 86400 IN    PTR     ns1.dani.com.

;; Query time: 3 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:40:50 UTC 2024
;; MSG SIZE  rcvd: 109

vagrant@ns2:~$ dig -x 192.168.57.11

; <<>> DiG 9.16.44-Debian <<>> -x 192.168.57.11
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 38371
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: ab63fc8148c0591d0100000065a6cdd732ea4ec991880284 (good)
;; QUESTION SECTION:
;11.57.168.192.in-addr.arpa.    IN      PTR

;; ANSWER SECTION:
11.57.168.192.in-addr.arpa. 86400 IN    PTR     ns2.dani.com.

;; Query time: 3 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:41:27 UTC 2024
;; MSG SIZE  rcvd: 109

vagrant@ns2:~$ dig -x 192.168.57.100

; <<>> DiG 9.16.44-Debian <<>> -x 192.168.57.100
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18632
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: cac236b7a67c60f30100000065a6cdf7e2631ea336be7465 (good)
;; QUESTION SECTION:
;100.57.168.192.in-addr.arpa.   IN      PTR

;; ANSWER SECTION:
100.57.168.192.in-addr.arpa. 86400 IN   PTR     server1.dani.com.

;; Query time: 7 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:41:59 UTC 2024
;; MSG SIZE  rcvd: 114

vagrant@ns2:~$ dig -x 192.168.57.101

; <<>> DiG 9.16.44-Debian <<>> -x 192.168.57.101
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63801
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: d544c9117c5c09ba0100000065a6ce060c0a8e60a83f8ee0 (good)
;; QUESTION SECTION:
;101.57.168.192.in-addr.arpa.   IN      PTR

;; ANSWER SECTION:
101.57.168.192.in-addr.arpa. 86400 IN   PTR     server2.dani.com.

;; Query time: 0 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:42:14 UTC 2024
;; MSG SIZE  rcvd: 114

vagrant@ns2:~$ dig -x 192.168.57.102

; <<>> DiG 9.16.44-Debian <<>> -x 192.168.57.102
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12062
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 6b80f816bd4a65520100000065a6ce1a35bdc50340da7450 (good)
;; QUESTION SECTION:
;102.57.168.192.in-addr.arpa.   IN      PTR

;; ANSWER SECTION:
102.57.168.192.in-addr.arpa. 86400 IN   PTR     mail.dani.com.

;; Query time: 3 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:42:34 UTC 2024
;; MSG SIZE  rcvd: 111

vagrant@ns2:~$ dig axfr dani.com

; <<>> DiG 9.16.44-Debian <<>> axfr dani.com
;; global options: +cmd
dani.com.               86400   IN      SOA     ns1.dani.com. admin.dani.com. 2024011401 3600 1800 604800 86400
dani.com.               86400   IN      NS      ns1.dani.com.
dani.com.               86400   IN      NS      ns2.dani.com.
www.dani.com.dani.com.  86400   IN      CNAME   server1.dani.com.dani.com.
mail.dani.com.          86400   IN      A       192.168.57.102
ns1.dani.com.           86400   IN      A       192.168.57.10
ns2.dani.com.           86400   IN      A       192.168.57.11
server1.dani.com.       86400   IN      A       192.168.57.100
server2.dani.com.       86400   IN      A       192.168.57.101
dani.com.               86400   IN      SOA     ns1.dani.com. admin.dani.com. 2024011401 3600 1800 604800 86400
;; Query time: 7 msec
;; SERVER: 192.168.57.10#53(192.168.57.10)
;; WHEN: Tue Jan 16 18:43:01 UTC 2024
;; XFR size: 10 records (messages 1, bytes 323)

Al hacer el dig en ns1 este da error

vagrant@ns1:~$ dig axfr dani.com

; <<>> DiG 9.16.44-Debian <<>> axfr dani.com
;; global options: +cmd
; Transfer failed.

Una vez comprobado este pasaríamos a comprobarlos igual que en ns2
```

 
