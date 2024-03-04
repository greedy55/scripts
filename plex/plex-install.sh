#!/bin/bash

sudo apt update -y

sudo apt install apt-transport-https curl -y

curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plexserver.gpg > /dev/null

echo deb [arch=amd64 signed-by=/usr/share/keyrings/plexserver.gpg] https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list

sudo apt update -y

sudo apt install plexmediaserver -y

sudo systemctl status plexmediaserver

sudo systemctl enable --now plexmediaserver  -y
