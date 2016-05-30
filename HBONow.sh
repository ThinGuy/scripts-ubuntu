#!/bin/bash

EXT_USER=`echo ~/.mozilla/firefox/*.default/extensions/`

get_xpi_id () { 
    addon_id_line=`unzip -p $1 install.rdf | egrep '<em:id>' -m 1`
    addon_id=`echo $addon_id_line | sed "s/.*>\(.*\)<.*/\1/"`
    echo "$addon_id"
}

get_xpi_name () { 
    addon_name_line=`unzip -p $1 install.rdf | egrep '<em:name>' -m 1`
    addon_name=`echo $addon_name_line | sed "s/.*>\(.*\)<.*/\1/"`
    echo "$addon_name"
}

install_addon () {
    xpi="${PWD}/${1}"
    extensions_path=$2
    new_filename=`get_xpi_id $xpi`.xpi
    new_filepath="${extensions_path}${new_filename}"
    addon_name=`get_xpi_name $xpi`
    if [ -f "$new_filepath" ]; then
        echo "File already exists: $new_filepath"
        echo "Skipping installation for addon $addon_name."
    else
        cp "$xpi" "$new_filepath"
    fi
}

#Install PipleLight
clear
printf “Installing pipelight…\n\n”
sudo add-apt-repository -y ppa:pipelight/stable
sudo apt-get update
sudo apt-get install -y --install-recommends pipelight-multi
sudo pipelight-plugin --update
sudo pipelight-plugin --enable flash
sudo pipelight-plugin --enable widevine
sudo pipelight-plugin --enable silverlight
sudo pipelight-plugin --unlock x64-flash
sudo pipelight-plugin --enable x64-flash
sudo pipelight-plugin --unlock shockwave
sudo pipelight-plugin --enable shockwave
sudo pipelight-plugin --update
sudo apt-get upgrade -y
printf “ Installing User Agent Overrider Plugin…\n\n”
mkdir -p $HOME/tmp_ext;$HOME/tmp_ext
wget https://addons.mozilla.org/firefox/downloads/latest/429678/addon-429678-latest.xpi
Install_addon addon-429678-latest.xpi “$EXT_USER”
rm -rf $HOME/tmp_ext;
printf “Launching Firefox…\n\n\tPlease be patient during Wine and Pipelight configuration…\n”
firefox &

