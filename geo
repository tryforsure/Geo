#!/bin/sh

#
# Shell utility for getting specific network info
# Author: Jake Meyer
# Github: https://github.com/jakewmeyer
#

# Parse arguments passed + help formatting
usage() {
    echo "Usage: geo [flag]"
    echo "  -w  Returns WAN IP"
    echo "  -l  Returns LAN IP(s)"
    echo "  -r  Returns Router IP"
    echo "  -d  Returns DNS Nameserver"
    echo "  -m  Returns MAC address for interface. Ex. eth0"
    echo "  -g  Returns Current IP Geodata"
    echo "Custom Geo Output =>"
    echo "[all] [query] [city] [region] [country] [zip] [isp]"
    echo "Example: geo -a 8.8.8.8 -o city,zip,isp"
    echo "  -o  [options] Returns Specific Geodata"
    echo "  -a  [address] For specific ip in -s"
    echo "  -v  Returns Version"
    echo "  -h  Returns Help Screen"
    exit
}

# Displays version number
version() {
  echo "Version 0.1.4";
}

# Fetches WAN ip address
wan_search() {
  dig +short myip.opendns.com @resolver1.opendns.com
}

# Fetches current LAN ip address
lan_search() {
    ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
}

# Fetches Router ip address
router_search() {
  if [ "$(uname)" == "Darwin" ]; then
    netstat -rn | grep default | head -1 | awk '{print$2}'
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    ip route | grep default | head -1 | awk '{print$3}'
  else
    echo "OS not supported"
    exit 1
  fi
}

# Fetches DNS nameserver
dns_search() {
  cat /etc/resolv.conf | grep -i ^nameserver | cut -d ' ' -f2
}

# Fetches MAC address of
mac_search() {
  ifconfig $MAC | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'
}

# Fetches current geodata based on ip
geodata_search() {
  curl -s "http://ip-api.com/line/?fields=query,city,region,country,zip,isp"
}

# Fetches specific geodata based on args
specific_geo() {
  if [ $OPTIONS == "all" ]; then
    curl -s "http://ip-api.com/line/${ADDRESS}?fields=query,city,region,country,zip,isp"
  else
    curl -s "http://ip-api.com/line/${ADDRESS}?fields=${OPTIONS}"
  fi
}

# Option parsing "controller"
optspec="wlrdm:go:a:vh*:"
while getopts "$optspec" optchar
do
    case "${optchar}" in
        w) wan_search ;;
        l) lan_search ;;
        r) router_search ;;
        d) dns_search ;;
        m) MAC=$OPTARG mac_search;;
        g) geodata_search ;;
        a) ADDRESS=$OPTARG ;;
        o) OPTIONS=$OPTARG specific_geo ;;
        v) version ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Makes geo command default to help screen for usability
if [ $# -eq 0 ];
then
    usage
    exit 0
fi
