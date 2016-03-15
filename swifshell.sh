#/usr/bin/env bash

function write_credentials() {
	if [ ! -f ~/.swiftshellrc ];then
		echo -e "\nWe can save your credentials.\n"
		echo -e "If you want practicality: \033[0;34m y \033[0m"
		echo -e "If you're paranoid about security: \033[0;31m n \033[0m \n"
		read -p"Would like to save then? (y/n):" save_credentials
		fi
	if [ "$save_credentials" == "y" ];then
		echo "OS_AUTH_URL=$OS_AUTH_URL" >  ~/.swiftshellrc
		echo "OS_TENANT_NAME=$OS_TENANT_NAME" >>  ~/.swiftshellrc
		echo "OS_USERNAME=$OS_USERNAME" >>  ~/.swiftshellrc
		echo "OS_PASSWORD=$OS_PASSWORD" >>  ~/.swiftshellrc		
		chmod 400  ~/.swiftshellrc
	else
		return 1
	fi
}

function read_credentials(){
	read -p"OS_AUTH_URL: " OS_AUTH_URL
	read -p"OS_TENANT_NAME: " OS_TENANT_NAME
	read -p"OS_ENDPOINT_TYPE: " OS_ENDPOINT_TYPE
	read -p"OS_USERNAME: " OS_USERNAME
	read -s -p "OS_PASSWORD (Type safe: we won't show it!): " OS_PASSWORD && echo
	read -p "Would like to ignore ssl verificarion? (y/n): " SWIFTCLIENT_INSECURE
	if [ "$SWIFTCLIENT_INSECURE" == "y" ];then
		SWIFTCLIENT_INSECURE=true
	fi
	if [ ! -f ~/.swiftshellrc ];then
		write_credentials
	fi
}

function load_credentials(){
	if [ ! -f ~/.swiftshellrc ];then
		read_credentials
	else
		echo "Loading ~/.swiftshellrc ..."
		for line in $(cat ~/.swiftshellrc);do
			export $line
		done
	fi
}

function authentication(){
	if [ "$SWIFTCLIENT_INSECURE" == "true" ];then
		insecure="-k"
	fi

	curl  -H 'Content-type: application/json' -d '{"auth": {"tenantName":"'"$OS_TENANT_NAME"'", "passwordCredentials": {"username":"'"$OS_USERNAME"'","password":"'"$OS_PASSWORD"'"}}}' https://auth.s3.globoi.com:5000/v2.0/tokens 2>/dev/null| python -m json.tool 
}

function get_token(){
	token=$(authentication|python -c 'import sys, json; print (json.load(sys.stdin)["access"]["token"]["id"])')
}

function get_admin_url(){
	adminURL=$(authentication|python -c 'import sys, json; print (json.load(sys.stdin)["access"]["serviceCatalog"][0]["endpoints"][0]["adminURL"])')
}

function list() {
	get_admin_url
	get_token
	if [ "$1" == "-l" ];then
		less="|less"
	else
		unset less
	fi
	eval curl -XGET -H \"X-Storage-Token: $token\" $adminURL 2>/dev/null ${less}

}

function cd(){
	pseudofolder=$pseudofolder\/container:$1
}

function run_command(){
	case $1 in
		clear) clear ;;
		exit) exit ;;
		echo) $@ ;;
		help) help ;;
		list) $@;;
		cd) $@;;
		*) echo "Unknown command" ;;
	esac
}

function help(){
	echo -e "\nAvailable commands: clear | exit | echo | help | list\n"
}


load_credentials
token=$(get_token)
adminURL=$(get_admin_url)
 
export pseudofolder="account:$OS_TENANT_NAME"
PS1="(swiftshell)[$pseudofolder]$ "
echo -e "\nType \"exit\" to leave swiftshell\n"

help

while true;do
	PS1="(swiftshell)[$pseudofolder]$ "
	read -p "$PS1" command
	run_command $command
done

