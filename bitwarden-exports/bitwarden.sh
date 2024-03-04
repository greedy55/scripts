#!/bin/bash
# Bitwarden CLI Vault Export Script
#  
# This script will backup the following:
#   - personal vault contents, password encrypted (or unencrypted)
#   - organizational vault contents (passwd encrypted or unencrypted)
#   - file attachments
# It will also report on whether there were items in the Trash that
# could not be exported.


# Constant and global variables

params_validated=0
Yellow='\033[0;33m'       # Yellow
IYellow='\033[0;93m'      # Yellow
IGreen='\033[0;92m'       # Green
Cyan='\033[0;36m'         # Cyan
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

echo Starting ...

#Set locations to save export files
if [[ -z "${OUTPUT_PATH}" ]]; then
    echo -e "\n${Cyan}Info: OUTPUT_PATH enviroment not provided. Using default value: /var/data"
    save_folder="/var/data/"
else
	save_folder="${OUTPUT_PATH}"
    if [[ ! -d "$save_folder" ]]
    then
        echo -e "\n${IYellow}ERROR: Could not find the folder in which to save the files: $save_folder "
        echo
        params_validated=-1
    fi
fi

#Set locations to save attachment files
if [[ -z "${ATTACHMENTS_PATH}" ]]; then
    save_folder_attachments="/var/attachments/"    
    echo -e "\n${Cyan}Info: ATTACHMENTS_PATH enviroment not provided. Using default value: /var/attachments"
else
	save_folder_attachments="${ATTACHMENTS_PATH}"
    if [[ ! -d "$save_folder_attachments" ]]
    then
        echo -e "\n${IYellow}ERROR: Could not find the folder in which to save the attachments files: $save_folder_attachments "
        echo
        params_validated=-1
    fi
fi



#Set Vaultwarden own server.
# To obtain your organization_id value, open a terminal and type:
#   bw login #(follow the prompts);
if [[ -z "${BW_URL_SERVER}" ]]; then
    echo -e -n $Cyan # set text = yellow
    echo -e "\nInfo: BW_SERVER enviroment not provided."

    echo -n "If you have your own Bitwarden or Vaulwarden server, set in the environment variable BW_URL_SERVER its url address. "
    echo -n "Example: https://skynet-vw.server.com"
    echo
else
	bw_url_server="${BW_URL_SERVER}"
fi


#Set Bitwarden session authentication.
# To obtain your organization_id value, open a terminal and type:
#   bw login #(follow the prompts);
if [[ -z "${BW_CLIENTID}" ]]; then

    echo -e "\n${IYellow}ERROR: BW_CLIENTID enviroment variable not provided, exiting..."

    echo -n "Your Bitwarden Personal API Key can be obtain in:"
    echo -n "https://bitwarden.com/help/personal-api-key/"
    params_validated=-1
else
    if test -f "${BW_CLIENTID}"; then
        client_id=$(<${BW_CLIENTID})
    else
	    client_id="${BW_CLIENTID}"
    fi

fi


if [[ -z "${BW_CLIENTSECRET}" ]]; then

    echo -e "\n${IYellow}ERROR: BW_CLIENTSECRET enviroment variable not provided, exiting..."

    echo -n "Your Bitwarden Personal API Key can be obtain in:"
    echo -n "https://bitwarden.com/help/personal-api-key/"
	params_validated=-1
else
    if test -f "${BW_CLIENTSECRET}"; then
        client_secret=$(<${BW_CLIENTSECRET})
    else
	    client_secret="${BW_CLIENTSECRET}"
    fi
    
fi


if [[ -z "${BW_PASSWORD}" ]]; then

    echo -e "\n${IYellow}ERROR: BW_PASSWORD enviroment variable not provided, exiting..."

	params_validated=-1
else

     if test -f "${BW_PASSWORD}"; then
        bw_password=$(<${BW_PASSWORD})
    else
	    bw_password="${BW_PASSWORD}"
    fi
fi


#Set Organization ID (if applicable)
if [[ -z "${BW_ORGANIZATIONS_LIST}" ]]; then
    echo -e "\n${Yellow} BW_ORGANIZATIONS_LIST enviroment not provided. All detected organizations will be exported. "
    echo -n "If you want to make a backup of specific organizations, set one or more organizations separated by comma"
    echo -n "To obtain your organization_id value, open a terminal and type:"
    echo "bw login #(follow the prompts); bw list organizations | jq -r '.[0] | .id'"
    echo "Example: cada13d7-5418-37ed-981b-be822121c593,cada13d7-5418-37ed-981b-be82219879878979,cada13d7-5418-37ed-981b-be822121c5435"
else
	organization_list="${BW_ORGANIZATIONS_LIST}"
fi



#Check export password 
if [[ -z "${EXPORT_PASSWORD}" ]]; then

    echo
    echo -e "\n${IYellow}-------------------------------------------------------------------------------------------------------------"
    echo -e "\n${IYellow}Warning: EXPORT_PASSWORD enviroment not provided. Exports require a password to securize your exported vault."
    echo -e "\n${IYellow}-------------------------------------------------------------------------------------------------------------"
    echo
    password1=""

else
    echo -e "\n${Cyan}Info:  Be sure to save your EXPORT_PASSWORD in a safe place!"
    if test -f "${EXPORT_PASSWORD}"; then
        password1=$(<${EXPORT_PASSWORD})
    else
	    password1="${EXPORT_PASSWORD}"
    fi
fi

# Check if required parameters has beed proviced.
if [[ $params_validated != 0 ]]
then
    echo -e "\n${IYellow}One or more required environment variables have not been set."
    echo -e "${IYellow}Please check the required environment variables:"
    echo -e "${IYellow}BW_CLIENTID,BW_CLIENTSECRET,BW_PASSWORD"
    exit -1
fi

echo "Starting exportint..."
echo 

if [[ $bw_url_server != "" ]]
then 
    echo "Setting custom server..."
    bw config server $bw_url_server
    echo
fi

BW_CLIENTID=$client_id
BW_CLIENTSECRET=$client_secret

#Login user if not already authenticated
if [[ $(bw status | jq -r .status) == "unauthenticated" ]]
then 
    echo "Performing login..."
    bw login --apikey --method 0 
fi
if [[ $(bw status | jq -r .status) == "unauthenticated" ]]
then 
    echo -e "\n${IYellow}ERROR: Failed to authenticate."
    echo
    exit 1
fi

#Unlock the vault
session_key=$(bw unlock $bw_password --raw)

#Verify that unlock succeeded
if [[ $session_key == "" ]]
then 
    echo -e "\n${IYellow}ERROR: Failed to authenticate."
    echo
    exit 1
else
    echo "Login successful."
    echo
fi

#Export the session key as an env variable (needed by BW CLI)
export BW_SESSION="$session_key" 

echo

#Check if the user has decided to enter a password or save unencrypted
if [[ $password1 == "" ]]
then 

    echo -e "\n${IYellow}WARNING! Your vault contents will be saved to an unencrypted file."   
    echo "WARNING! Your vault contents will be saved to an unencrypted file."     


else
    echo -e "\n${Cyan}Info: Password for encrypted export has been provided."   
fi


echo "Performing vault exports..."

# 1. Export the personal vault 
if [[ ! -d "$save_folder" ]]
then
    echo -e "\n${IYellow}ERROR: Could not find the folder in which to save the files. Path: $save_folder"
    echo
    exit 1
fi

if [[ $password1 == "" ]]
then
    echo
    echo "Exporting personal vault to an unencrypted file..."
    bw export --format json --output $save_folder
else
    echo 
    echo "Exporting personal vault to a password-encrypted file..."
    bw export --format encrypted_json --password $password1 --output $save_folder
fi

if [[ $organization_list == "" ]]
then
    list=$(bw list organizations | jq -r '.[] | .id' | tr '\n' ', ')
    if [[ ! -z "$list" ]]
    then 
        organization_list=${list::-1}
        if [[ ! -z "$organization_list" ]]
        then 
                echo -e "\n${Cyan}Info: No  BW_ORGANIZATIONS_LIST provided. Exporting all organizations detected in vault"
        fi
    fi
fi

# 2. Export the organization vault (if specified) 
if [[ ! -z "$organization_list" ]]
then 
    IFS=', ' read -r -a array <<< "$organization_list" 
    for org_id in "${array[@]}"
    do
        if [[ $password1 == "" ]]
        then
            echo
            echo "Exporting organization vault to an unencrypted file..."
            bw export --organizationid $org_id --format json --output $save_folder
        else
            echo 
            echo "Exporting organization vault to a password-encrypted file..."
            bw export --organizationid $org_id --format encrypted_json --password $password1 --output $save_folder
        fi
    done
else
    echo
    echo "No organizational vault exists, so nothing to export."
fi


# 3. Download all attachments (file backup)
#First download attachments in vault
if [[ $(bw list items | jq -r '.[] | select(.attachments != null)') != "" ]]
then
    echo
    echo "Saving attachments..."
    bash <(bw list items | jq -r '.[]  | select(.attachments != null) | "bw get attachment \"\(.attachments[].fileName)\" --itemid \(.id) --output \"'$save_folder_attachments'\(.name)/\""' )
else
    echo
    echo "No attachments exist, so nothing to export."
fi 

echo
echo "Vault export complete."


# 4. Report items in the Trash (cannot be exported)
trash_count=$(bw list items --trash | jq -r '. | length')

if [[ $trash_count > 0 ]]
then

    echo -e "\n${Cyan}Info: You have $trash_count items in the trash that cannot be exported."

fi



echo
bw lock 
bw logout
BW_CLIENTID=
BW_CLIENTSECRET=
BW_SESSION=
echo -e "\n${IGreen}Info: Exporting finished. Have a good day"
echo