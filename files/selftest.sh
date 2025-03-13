#!/usr/bin/env bash
#set -euo pipefail

export COLOR_RESET='\e[0m' # No Color
export COLOR_BLACK='\e[0;30m'
export COLOR_RED='\e[0;31m'
export COLOR_GREEN='\e[0;32m'


if ! test -t 1; then
	# wait a bit for things to stabilize
	sleep 10
	# We are not running in a TTY. Open in a terminal to show output
	i3-msg "workspace 9; exec lxterminal -e 'bash $0'"
fi

failures=0

run_test() {
	local name_of_test
	local title
	name_of_test="$1"
	title="$2"

	echo -n "Testing if $title... "

	local output
	local result
	output="$($name_of_test 2>&1)"
	result="$?"

	if [[ "$result" -eq 0 ]]; then
		echo -e "${COLOR_GREEN}OK${COLOR_RESET}"
	else
		echo -e "${COLOR_RED}FAIL${COLOR_RESET}"
		echo "Output:"
		echo "$output"
		failures=1
	fi
}

network_up() {
	ip a show eth0 | grep 'inet 10' || sleep 1
	ip a show eth0 | grep 'inet 10' || sleep 3
	ip a show eth0 | grep 'inet 10' || sleep 5
	ip a show eth0 | grep 'inet 10'
}

ping_studiosw1() {
	ping -c1 -W2 10.1.0.22
}
ping_studiosw2() {
	ping -c1 -W2 10.1.0.23
}
ping_tekniikkasw1() {
	ping -c1 -W2 10.1.0.21
}
ping_local_gw() {
	ping -c1 -W2 10.1.0.1
}
ping_internet() {
	ping -c1 -W2 1.1.1.1
}
ping_dc() {
	ping -c1 -W2 10.36.0.1
}
ping_napster() {
	ping -c1 -W2 10.1.0.1
}
ping_tuottaja() {
	ping -c1 -W2 10.1.0.54
}

dns_public() {
	host -W2 www.google.com	
}
dns_idm() {
	host -W2 napster.idm.wappuradio.fi
}
dns_levykanta() {
	host -W2 i.levykanta.wappuradio.fi
}
ping_levykanta() {
	ping -c1 -W2 i.levykanta.wappuradio.fi
}
curl_levykanta() {
	curl -m2 i.levykanta.wappuradio.fi
}
nfs_levykanta() {
	ssh wappuradio@winamp mount | grep '/var/lib/mpd/music'
}
songs_levykanta() {
	count="$(ssh wappuradio@winamp ls -lah /var/lib/mpd/music/ | wc -l)"
	[[ "$count" -gt 10000 ]]
}
mpd_levykanta() {
	ssh wappuradio@winamp ps aux | grep 'bin/mpd'
}

ping_qltools() {
	ping -c1 -W2 qltools.idm.wappuradio.fi
}
qlapi() {
	nc -vz -w2 qltools.idm.wappuradio.fi 8083
}
ping_ql() {
	ping -c1 -W2 10.1.0.15
}
mikit_node() {
	ps aux | grep -v grep | grep 'node mikit.js'
}
mikit_port() {
	nc -vz -w2 localhost 1337
}
curl_mikit() {
	curl -m2 https://intra.wappuradio.fi/mikit/
}

chromium() {
	ps aux | grep -v grep | grep chromium
}

chromium_url() {
	curl -m2 https://wappuradio.fi/files/vituntelkkari.html
}

echo "Running self test"

run_test network_up "local network interface is up"
run_test ping_studiosw1 "studio-sw1 (10.1.0.22) is pingable"
run_test ping_studiosw2 "studio-sw2 (10.1.0.23) is pingable"
run_test ping_tekniikkasw1 "tekniikka-sw1 in tech rack (10.1.0.21) is pingable"
run_test ping_local_gw "local gateway (SRX firewall in tech rack) responds to ping"
run_test ping_internet "a host on the internet (1.1.1.1) is pingable"
run_test ping_dc "a host in the datacenter (10.36.0.1) is pingable"
run_test ping_tuottaja "producer desktop (tuottaja, 10.1.0.54) is pingable"

run_test dns_public "public DNS names (www.google.com) resolve"
run_test dns_idm "internal DNS names (napster.idm.wappuradio.fi) resolve"
run_test dns_levykanta "levykanta internal name (i.levykanta.wappuradio.fi) resolves"

run_test ping_napster "music player NAS (napster) is pingable"
run_test ping_levykanta "levykanta responds to ping"
run_test curl_levykanta "warmup responds on levykanta"
run_test nfs_levykanta "NFS is mounted on levykanta"
run_test songs_levykanta "levykanta shows >10k songs"
run_test mpd_levykanta "levykanta has MPD running"

run_test ping_ql "QL is pingable"
run_test ping_qltools "qltools (VM) is pingable"
run_test mikit_node "mikit.service is running (depends on qltools)"
run_test mikit_port "mikit.service listens on port 1337"
run_test curl_mikit "mikit.service is reachable via https://intra.wappuradio.fi/mikit/"

run_test chromium "chromium is running"
run_test chromium_url "https://wappuradio.fi/files/vituntelkkari.html opens"

echo ""
echo -n "Overall status: "
if [[ "$failures" -gt 0 ]]; then
	echo -e "${COLOR_RED}FAIL${COLOR_RESET}"
	sleep 300
else
	echo -e "${COLOR_GREEN}OK${COLOR_RESET}"
	sleep 10
fi

i3-msg workspace 1
