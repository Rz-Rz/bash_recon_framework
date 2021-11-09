#! /bin/bash
target=$1
# comm -13 ~/opt/list/general/eng/general-words.txt sorted.txt | wc -l

huntr_seekr(){
	cat $list | httpx -silent | anew live_host.txt | hakrawler -subs | anew endpoints.txt | while read url; do ua=$(shuf -n 1 ./txt/ua.txt) && curl -A "$ua" --insecure $url | tok | tr '[:upper:]' '[:lower:]' | anew words.txt; done
	cat ~/opt/work/rocketleague.com/subdomains_rocketleague.com.txt | httpx -silent | while read url; do ua=$(shuf -n 1 ./txt/ua.txt) && curl -A "$ua" --insecure $url | tok | tr '[:upper:]' '[:lower:]' | sort -u | tee -a words.txt; done
}
#cat subdomains.txt urls.txt endpoints.txt | haklistgen | anew wordlist.txt;

