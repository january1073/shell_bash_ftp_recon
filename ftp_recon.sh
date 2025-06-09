#!/bin/bash
# FTP Reconnaissance Script
# Usage: ./ftp_recon.sh <target_ip>

TARGET=$1
WORDLIST="/usr/share/wordlists/dirb/common.txt"

echo "[+] Starting FTP reconnaissance on $TARGET"

# Test anonymous access
{
    echo "user anonymous anonymous@test.com"
    sleep 2
    echo "quit"
} | ftp -n -v "$TARGET" > /dev/null 2>&1

# Re-run to capture response for access check
anon_check=$(echo -e "user anonymous anonymous@test.com\nquit" | ftp -n -v "$TARGET" 2>&1)

if echo "$anon_check" | grep -q "230"; then
    echo "[+] Anonymous FTP access confirmed"
    
    echo "[+] Enumerating directories..."
    found_dirs=0
    while read -r dir; do
        result=$(echo -e "user anonymous anonymous@test.com\ncd $dir\nquit" | ftp -n -v "$TARGET" 2>&1)
        echo "$result" | grep -q "250" && {
            echo "[FOUND] $dir"
            ((found_dirs++))
        }
    done < "$WORDLIST"
    
    echo "[+] Found $found_dirs accessible directories"
    
    echo "[+] Listing root directory contents..."
    {
        echo "user anonymous anonymous@test.com"
        sleep 1
        echo "binary"
        sleep 1
        echo "ls -la"
        sleep 2
        echo "quit"
    } | ftp -n -v "$TARGET" > ftp_listing.txt 2>&1
    
    echo "[+] Root directory contents:"
    grep -v '^[0-9]' ftp_listing.txt | grep -v '^ftp>' | grep -v '^local:'
    
else
    echo "[-] Anonymous access denied"
fi

rm -f ftp_listing.txt
