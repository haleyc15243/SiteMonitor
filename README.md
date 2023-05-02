# SiteMonitor
A simple script for observing changes to websites. The intent is that this be run at some regular interval using cron.

02-05-2023
At the moment this takes some initial setup. Automation of this setup is coming, but for now, here are the steps to follow to get this running on a regular basis.
 - Clone the repository to a local location on your computer.
 - In a terminal window, cd to the location at which you cloned the repository and run 'chmod +x siteMonitor.sh'
 - If you are using a mac, and cloned the repo to a location that is protected by your system's policy (Such as ~/User/__/Documents or ~/User/__/Downloads) and intend to run this automatically using cron, you may need to add cron to the Full Disk Access apps. If so:
    - Open System Preferences > Security & Privacy > Privacy > Full Disk Access apps/execs
    - Click the '+' button
    - Type '⌘' + '⇧' + 'G'
    - Enter /usr/sbin
    - Double click the 'cron' file.
 - Once this is complete you can add siteMonitor.sh as a cron job to run as frequently as you would like.
