$TTL 3600
@   IN  SOA ns1.{{DOMAIN}}. admin.{{DOMAIN}}. (
        {{SERIAL}}  ; Serial
        3600        ; Refresh
        900         ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
    )

; Name Servers
@       IN  NS  ns1.{{DOMAIN}}.
@       IN  NS  ns2.{{DOMAIN}}.

; A Records
@       IN  A   {{SERVER_IP}}
ns1     IN  A   {{SERVER_IP}}
ns2     IN  A   {{SERVER_IP}}
www     IN  A   {{SERVER_IP}}

; Mail
@       IN  MX  10  mail.{{DOMAIN}}.
mail    IN  A   {{SERVER_IP}}

; SPF
@       IN  TXT "v=spf1 mx a ~all"
