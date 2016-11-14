#!/usr/bin/env bash

red=`tput setaf 1`
green=`tput setaf 2`
white=`tput setaf 7`
reset=`tput sgr0`

function verify_packages
{
    # Check for all dependencies

    DEPENDENCIES="libqt4-dev qt4-dev-tools python3-pyqt4 pyqt4-dev-tools ladish python3-dbus.mainloop.qt"
    stringarray=($DEPENDENCIES)

    export dependencies=""
    for depends in "${stringarray[@]}"
    do
        if [ $(dpkg-query -W -f='${Status}' $depends 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            dependencies+=" $depends"
        fi
    done
    if [ "$dependencies" != "" ]; then
        echo -e "\n${green}Missing package dependencies: ${red}$dependencies\n"
        echo -e "${green}try '${white}sudo apt install $dependencies${green}'\n"
        echo -e "${reset}"
        exit 1
    fi
}

# build linuxsampler packages


function build_cadence
{
    if [ -e cadence-git ]; then
        rm -fr cadence-git
    fi
    git clone https://github.com/falkTX/Cadence.git cadence-git
    cd cadence-git
    cp -pr  ../../debian .

    CURRENTBUILDDATE=$(date --utc '+%a, %d %b %Y %H:%M:%S %z')
    CURRENTDATE=$(date +%Y%m%d)
    CURRENTGITHASH=$(git rev-parse --short=8 HEAD)

    echo "Setting date to $CURRENTDATE"
    sed -i "s/insertdate/$CURRENTDATE/g" debian/changelog

    echo "Using git hash $CURRENTGITHASH"
    sed -i "s/githash/$CURRENTGITHASH/g" debian/changelog

    echo "Build time and date set to '$CURRENTBUILDDATE'"
    sed -i "s/buildtimeanddate/$CURRENTBUILDDATE/g" debian/changelog

    dpkg-buildpackage -uc -us -b
    cd ..
}

function install_cadence
{
    sudo dpkg -i cadence*.deb
}

function backup_debs
{
    if [ ! -e ../debs ]; then
        mkdir ../debs
    fi
    rm ../debs/*.deb > /dev/null
    mv *.deb ../debs
}

function clean_up
{
    rm -fr build-cadence
}

###########################################################
#
#    Carla audio plugin installation script for Ubuntu
#
###########################################################

if [ ! -e build-cadence ]; then
    mkdir build-cadence
fi
cd build-cadence

echo -e "\nVerifying package dependencies\n"
verify_packages

echo -e "\nbuilding cadence\n"
build_cadence
echo -e "\ninstalling cadence\n"
install_cadence

echo -e "\nbackup packages\n"
backup_debs

cd ..

#echo -e "\nclean up\n"
#clean_up
