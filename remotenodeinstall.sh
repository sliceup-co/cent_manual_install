#!/bin/bash

#Install code on remote devices


#Make sure the tar file is present.
    executablestest=$(ls executables.tar.gz)
                   if [[ "$executablestest" != "executables.tar.gz" ]]; then
                        echo -e "\e[96m The file executables.tar.gz was not found in the same directory as the install script SSH. \e[39m"
                        echo -e "\e[96m Please resolve and run the script again. \e[39m"
                        exit
                    fi

# Files that need to be present on remote nodes
# executables.tar.gz remotenosu.sh workerstart.sh sliceworker.service


####Need to set IP for Prime node
echo -e "\e[96m  What is the IP address of the Prime node? \e[39m"

read masterip


echo -e "\e[96m  What is the IP address of this device? \e[39m"
read address

#Run Remote Script

    echo -e "\e[96m Starting Install of"; hostname; echo -e " \e[39m"
     yum update -y

#create directory structure
     mkdir /opt/sliceup


# get files remove this section and uncomment CURL when available"


    echo -e "\e[96m Extracting Files and Installing Java  \e[39m"
     tar -xvzf executables.tar.gz --directory /opt/sliceup/
     mkdir /opt/sliceup/scripts
     chmod -R a+r /opt/sliceup
     cuser=$(whoami)
     chown -R $cuser /opt/sliceup
     yum install java-11-openjdk -y
     yum install java-11-openjdk-headless -y

     yum install python-devel -y
     yum install python3-devel -y
     yum groupinstall 'Development Tools' -y
     yum install PyOpenGL libtool autoconf pkgconfig python-pillow qt-devel python-tools python-pyside python2-pyside python36-pyside qt4-devel PyQt4-devel qt-x11 -y
     yum install python3-pip -y
     python3 -m pip install requests 2>/dev/null
     python3 -m pip install selenium 2>/dev/null


     mv workerstart.sh /opt/sliceup/scripts/workerstart.sh
    # mv workerinstall.sh /opt/sliceup/scripts/workerinstall.sh
     chmod +x /opt/sliceup/scripts/workerstart.sh
     mv sliceworker.service /etc/systemd/system/sliceworker.service



#Inside each of the worker Nodes
    echo -e "\e[96m Replacing Variable Options  \e[39m"
    export _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true"
    #Replace {MASTER_IP} in executables/flink-1.10.0/conf/flink-conf.yaml
    # sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/flink-1.10.0/conf/flink-conf.yaml




#####AFter Remote Run
	    
sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/flink-1.10.0/conf/flink-conf.yaml


sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/conf.ini


sed -i "s/{WORKER_IP}/$address/g" /opt/sliceup/executables/conf.ini



#Enable service at start
    echo -e "\e[96m Enabling StartUp service  \e[39m"
    systemctl enable sliceworker
 

systemctl start sliceworker.service

