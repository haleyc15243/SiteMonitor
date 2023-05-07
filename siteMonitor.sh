#!/bin/bash

changes_at="Changes at"

curr_dir="$(dirname "$(readlink -f "$0")")"
hash_file="$curr_dir/hashes.txt"
sites_file="$curr_dir/sites.txt"
email_file="$curr_dir/email.txt"
last_checked_file="$curr_dir/lastChecked.txt"
pw_file="$curr_dir/pw.txt"
log_file="$curr_dir/log.txt"

mail_from="site.monitor.no.reply@gmail.com"
from_string="From: Site Monitor"
to_string="To: You"
subject_string="Subject: Website Changes"
body_changes="Sites that have changed"
since_string="since"

setupLogging() {
	if [ ! -f "$log_file" ]; then
		touch "$log_file"
	fi
	exec 3>&1 1>${log_file} 2>&1
}

logToOut() {
	echo -e "$1\n" 1>&3
}

logToFile() {
	echo -e "$1\n"
}

log() {
	echo -e "$1\n" | tee /dev/fd/3
}

prompt() {
	read -p "$1" $2 2>&3
}

getEmailContent() {
	last_checked_string=''
	if [[ ! -f "$last_checked_file" ]]; then
		logToFile "Last checked file doesn't exist... Creating."
		touch "$last_checked_file"
		last_checked_string="$body_changes"
	else
		last_checked_time=$(date -r "$last_checked_file" "+%Y-%m-%d %H:%M:%S") 
		log "Last checked: $last_checked_time"
		last_checked_string="$body_changes $since_string: $last_checked_time"
	fi
	logToFile "Email contents is:\n$from_string\n$to_string\n$subject_string\n\n$last_checked_string\n\t$1"
	eval "$2='$from_string\n$to_string\n$subject_string\n\n$last_checked_string\n$1'"
}

getPassword() {
	pw=''
	if [ ! -f "$pw_file" ]; then
		logToFile "Password file doesn't exist, getting password..."
		prompt "Enter the password: " pw
		logToFile "User entered password: $pw"
		echo $pw > "$pw_file"
	else
		pw=$(<"$pw_file")
		if [ -z "$pw" ]; then
			logToFile "Password file exists, but is empty. Getting password...\n"
			prompt "Re-enter the password: " pw
			logToFile "User entered password: $pw"
			echo $pw > "$pw_file"
		fi
	fi
	eval "$1=$pw"
}

getUserEmail() {
	if [ ! -f "$email_file" ]; then
		logToFile "Email file doesn't exist, getting email..."
		touch "$email_file"
		prompt "Enter the email where you would like to receive updates: " email
		logToFile "User entered email: $email"
		echo $email > "$email_file"
	else
		email=$(<"$email_file")
		if [ -z "$email" ]; then
			logToFile "Email file exists, but is empty. Getting email..."
			prompt "Enter the email where you would like to receive updates: " email
			logToFile "User entered email: $email"
			echo $email > "$email_file"
		#else
			#email="'head -1 $email_file'"
		fi
	fi
	eval "$1=$email"
}

checkHashFile() {
	first_run=0
	if [ ! -f "$hash_file" ]; then
		logToFile "Hash file does not exist... Creating"
		touch hashes.txt
		first_run=1
	else
		hash_contents=$(<"$hash_file")
		if [ -z "$hash_contents" ]; then
			logToFile "Hash file exists but is empty"
			first_run=1
		else
			first_run=0
		fi
	fi
	eval "$1=first_run"
}

doSiteEvals() {
	paste -d '\n' "$sites_file" "$hash_file" > combined.txt
	logToFile "\nCombined sites and hashes result is:\n\n$(cat combined.txt)\n"
	changed_sites=''
	line_count=0
	while read -r site_url && read -r old_hash;
	do
		logToFile "Reading site $line_count: $site_url..."
		#can this be improved to work without a file?
		curl -L $site_url > site.txt
		hash=($(shasum -a 256 $site_file))
		logToFile "\tHash is $hash"
		if [ -z "$old_hash" ]; then
			logToFile "\tSite $site_url is new!"
			if [ first_run ]; then
				echo "$hash" > "$hash_file"
			else
				echo $"\n$hash" >> "$hash_file"
			fi
		else
			logToFile "Old hash is: $old_hash"
			if [ "$old_hash" != "$hash" ]; then
				log "\t Site $line_count has changed!"
				changed_sites="${changed_sites}\n${site_url}"
				logToFile "Changed sites is: $changed_sites"
				sed -i '$(line_count)s/.*/$hash' "$hash_file"
			else
				logToFile "\tSite $site_url has not changed."
			fi
			((line_count++))
		fi
	done<combined.txt
	echo "$(date "+%Y-%m-%d %H:%M:%S")" > "$last_checked_file"
	eval "$1=$changed_sites"
}

if [[ ! -f "$sites_file" ]]; then
	touch sites.txt
	printf "File: \'sites.txt\' is missing.\nI have created it for you, please add one url per line for each site you want to monitor.\n"
else
	setupLogging
	getPassword pw
	getUserEmail email
	checkHashFile first_run
	doSiteEvals changed_sites
	
	getEmailContent "$changed_sites" full_contents
	if [ ! -z $changed_sites ]; then
		logToOut "Changes are $changed_sites"
		curl -L smtps://smtp.gmail.com:465 -v --ssl-reqd --mail-from "$mail_from" --mail-rcpt "$email" --ssl -u $mail_from:$pw -T <(echo -e "$full_contents")
	fi
	rm combined.txt
	rm site.txt
	logToOut "File compare complete!"
fi



