#! /bin/bash

target=$1
js_target=$target
target=${target//https:\/\//}
target_name=`echo $target | sed -E 's/\.org|\.com|\.net|\.com\.ac|\.edu\.ac|\.gov\.ac|\.net\.ac|\.mil\.ac|\.org\.ac//'`
resultDir=/home/afterburner/opt/work/$target
mkdir -p $resultDir
resolvers=/home/afterburner/opt/list/resolvers/resolvers.txt

passive(){
	amass enum -src -ip -rf $resolvers -nolocaldb -noalts -d $target -o $resultDir/amass_subs_$target.txt
	subfinder -d $target -all -rL $resolvers -o $resultDir/subfinder_subs_$target.txt
	crobat -s $target | sort -u | tee -a $resultDir/crobat_subs_$target.txt
	echo "$target" | gauplus -b png,jpg,gif,css,jpeg,png,wolf,bmp -subs --random-agent -t 25 | anew $resultDir/gau_$target.txt
	python3 /home/afterburner/opt/JSFinder/JSFinder.py -u $js_target -d -os $resultDir/JS_subs_$target.txt
	~/opt/github-search/github-subdomains.py -d $target | tee -a $resultDir/github_subs_$target.txt
	fierce --domain $target --wide > $resultDir/fierce_subsip_$target.txt
	python3 /home/afterburner/opt/ctfr/ctfr.py -d $target -o $resultDir/ctfr_subs_$target.txt
	delator -d $target -s crt | tee -a $resultDir/delator_subs_$target.txt	
}
data_processing(){
	cat $resultDir/amass_subs_$target.txt | cut -d']' -f 2 | awk '{print $1}' | sort -u >> $resultDir/tmp_subs.txt
	cat $resultDir/subfinder_subs_$target.txt | sort -u >> $resultDir/tmp_subs.txt
	cat $resultDir/crobat_subs_$target.txt | sort -u >> $resultDir/tmp_subs.txt
	cat $resultDir/gau_subs_$target.txt | sort -u >> $resultDir/tmp_subs.txt
	cat $resultDir/JS_subs_$target.txt | sort -u >> $resultDir/tmp_subs.txt
	cat $resultDir/ctfr_subs_$target.txt | grep -v '^*' | sort -u >> $resultDir/tmp_subs.txt
	cat $resultDir/delator_subs_$target.txt | grep -v '^*' | sort -u >> $resultDir/tmp_subs.txt
	cat $resultDir/fierce_subsip_$target.txt | grep 'Found' | cut -d' ' -f 2 | sed 's/\.$//' | sort -u >> $resultDir/tmp_subs.txt
	#cat $resultDir/puredns_subs_$target.txt | sort -u >> $resultDir/tmp_subs.txt
	cat $resultDir/gau_$target.txt | unfurl domains | anew $resultDir/gau_subs_$target.txt
	cat $resultDir/gau_$target.txt | unfurl keys | anew $resultDir/gau_keys_$target.txt
	cat $resultDir/gau_$target.txt | unfurl paths | anew $resultDir/gau_paths_$target.txt
	cat $resultDir/gau_subs_$target.txt | anew $resultDir/tmp_subs.txt
	cat $resultDir/tmp_subs.txt | sort -u > $resultDir/all_subs.txt && rm $resultDir/tmp_subs.txt

}
wordlist(){
	cat $resultDir/all_subs.txt | httpx -silent -ports 80,443,81,8443,8080,8000,10000,9000 | anew $resultDir/live_hosts.txt | hakrawler -subs | grep $target_name | anew $resultDir/endpoints.txt | while read url; do ua=$(shuf -n 1 ~/opt/list/ua/ua.txt) && curl -A "$ua" --insecure $url | tok | tr '[:upper:]' '[:lower:]' | anew $resultDir/words.txt; done
	cat $resultDir/gau_subs_$target.txt | tok | anew $resultDir/words.txt
	cat $resultDir/gau_keys_$target.txt | tok | anew $resultDir/words.txt
	sed 's#/#\n#g' $resultDir/gau_paths_$target.txt | anew $resultDir/words.txt 
	cat $resultDir/words.txt | sort -u > $resultDir/wordlist.txt
	comm -13 ~/opt/list/general/eng/general-words.txt $resultDir/wordlist.txt > wordlist_cleaned.txt
}
ip_gathering(){
	cat $resultDir/all_subs.txt | dnsx -silent -a -resp-only | tee -a $resultDir/ips.txt
	cat $resultDir/fierce_subsip_$target.txt | grep 'Found' | cut -d' ' -f 3 | sed 's/(//' | sed 's/)//' | anew $resultDir/ips.txt
	cat $resultDir/amass_subs_$target.txt | cut -d']' -f 2 | awk '{print $2}' | tr ',' '\n' | anew $resultDir/ips.txt
	cat $resultDir/ips.txt | cf-check | anew $resultDir/checked_ips.txt	
}
active(){
	#puredns bruteforce /home/afterburner/opt/list/subdomain/maximumv2.txt_cleaned $target -r $resolvers --write $resultDir/puredns_subs_$target.txt
	gospider -d 0 -s $js_target | grep -Eo '(http|https)://[^/"]+' | grep $target_name | tee -a $resultDir/gospider_subs_$target.txt
}


passive
active
data_processing
ip_gathering
wordlist
