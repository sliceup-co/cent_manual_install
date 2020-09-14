#!/bin/bash
    echo -e "\e[96m Do not run this script with . The script will use sudo if appropriate.\e[39m"
    echo -e "\e[96m This script is meant to be run with Centos 7. It might work with higher versions but it hasn't been tested.\e[39m"
    echo -e "\e[96m Please ensure that all servers in the cluster have full access to each other.\e[39m"
    echo -e "\e[96m All servers should have rsync installed. The firewall should be disabled and stopped or the appropriate config should have been configured\e[39m"
    echo -e "\e[96m Make sure that all the worker nodes have the same password. \e[39m"
    echo -e "\e[96m When complete, go to http://ipaddress_of_prime:3000 Default user: admin, password: admin.\e[39m"
    echo -e "\e[96m Press Enter to continue. \e[39m"
    read y 

#Make sure the tar file is present.
    executablestest=$(ls ../executables.tar.gz)
                   if [[ "$executablestest" != "executables.tar.gz" ]]; then
                        echo -e "\e[96m The file executables.tar.gz was not found in the same directory as the install script SSH. \e[39m"
                        echo -e "\e[96m Please resolve and run the script again. \e[39m"
                        exit
                    fi


#Get password for postgres
    echo -e "\e[96m Please choose and enter the password for the database. \e[39m"
    read psqlpass


# Determine storage mount to be used for Database


        clear
        echo -e "\e[96m It is important to choose the correct database data directory \e[39m"
        echo -e "\e[96m This is the location where your database will be installed. If there is not enough space, the system will not function \e[39m"


        echo -e "\e[96m  Use a directory with approx 1Tb of storage or more.\e[39m"
        echo -e "\e[96m Look at the \"Avail\" column and note the Mounted on option with the required space \e[39m"
        echo -e "\e[96m Here is your directory structure \e[39m"
	echo " "
       
         df -h

        echo " "
        echo -e "\e[96m If \"/\" or \"/var/\" has the correctly allocated space, you can use system defaults \e[39m"
        echo -e "\e[96m Otherwise, a custom directory will need to be used \e[39m"
        echo -e "\e[96m Does \e[39m"
        echo -e "\e[96m / \e[39m"
        echo -e "\e[96m or \e[39m"
        echo -e "\e[96m /var \e[39m"
        echo -e "\e[96m directories have enough allocated space? \e[39m"

        echo -e "\e[96m Type \"y\" to use the default config or \"n\" to configure a custom database storage and press Enter\e[39m"

            read s
	            if [ "$s" = "N" ] || [ "$s" = "n" ]; then

                    clear
                    echo -e "\e[96m Here is your directory structure again \e[39m"
                    echo " "
                     df -h
                    echo " "
                    echo -e "\e[96m Copy and past the exact text from the \"Mounted on\" column \e[39m"
                    echo -e "\e[96m For example: If Avail says 970G, and the corresponding Mounted column is /home, and it is the mount you want to use; \e[39m"
                    echo -e "\e[96m you would copy and paste the following: \e[39m"
                    echo " "
                    echo -e "\e[96m /home \e[39m"
                    echo -e "\e[96m Copy and paste your choice now and press Enter \e[39m"
                    read mount
                    

	            elif [ "$s" = "Y" ] || [ "$s" = "y" ]; then
	             
	                 echo -e "\e[96m Using default storage for the database \e[39m"

	             sleep 2
	             	else
	                    echo "Invalid selection. Run the script again"
	             exit
	            fi




#Get node IP info from end user
    echo -e "\e[96m Enter a comma seperated list of all workernode IP addresses. (This is the prime node)"
    echo -e "Example 192.0.2.1,192.0.2.33,192.0.2.99 \e[39m"
    #read ipaddressin
    IFS=',' read -r -a ipaddresses

# Get IP address of the Prime node
    echo -e "\e[96m This device is being configured as the Prime node. Enter the IP address of the interface used to communicate with the worker nodes."
    echo -e "\e[96m e.g. 192.0.2.100 \e[39m"
    read masterip


#Get syslog port
    echo -e "\e[96m Enter the port that will be used to receive logs. (e.g. 514) \e[39m"
    read port


# Check for Ping reachablility
    for address in "${ipaddresses[@]}"
         do

            pingtest=$(ping -nq -w 2 -c 1 $address | grep -o "=")    

                    if [[ "$pingtest" != "=" ]]; then	
                        echo -e "\e[96m $address is not reachable via ping. \e[39m"
                        echo -e "\e[96m Please resolve and try again. \e[39m"
                        exit
                      
                    fi

         done

     echo -e "\e[96m Success! All devices rechable via ping. Continuing. \e[39m"
     sleep 2





##########################Begin Prime Install#####################################

	echo -e "\e[96m Starting Prime's install. \e[39m"

#update system
     yum update -y
#create directory structure
     mkdir /opt/sliceup
     mkdir /opt/sliceup/scripts
     chmod -R a+r /opt/sliceup
     mkdir /opt/sliceup/dashboards
     mkdir /opt/sliceup/ssl
    cuser=$(whoami)
     chown -R $cuser /opt/sliceup

   # rm workerinstall.sh
    mv masterstart.sh /opt/sliceup/scripts/masterstart.sh
   # mv masterinstall.sh /opt/sliceup/scripts/masterinstall.sh
    chmod +x /opt/sliceup/scripts/masterstart.sh
    mv slicemaster.service /etc/systemd/system/slicemaster.service
	

# begin install

#java install
#curl https://transfer.sh/wROIc/executables.tar.gz -o executables.tar.gz
    echo -e "\e[96m Extract Files and install JAVA  \e[39m"
     tar -xvzf executables.tar.gz --directory /opt/sliceup/
    # chmod -R a+r /opt/sliceup
     yum install java-11-openjdk -y
     yum install java-11-openjdk-headless -y

#Vector Install
#changing curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | sh
    echo -e "\e[96m Install Vector and Postgres  \e[39m"
    curl --proto '=https' --tlsv1.2 -O https://packages.timber.io/vector/0.9.X/vector-x86_64.rpm
     rpm -i vector-x86_64.rpm
     systemctl start vector

#Postgres Install
     yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y
     yum install postgresql10-server postgresql10-contrib postgresql10-devel -y

#########Postgres directory###########

###If data mount is not default e.g. $s=n

	            if [ "$s" = "N" ] || [ "$s" = "n" ]; then
                     mkdir -p $mount/.sliceup-data/
                     mkdir -p $mount/.sliceup-data/kafka
                     mkdir -p $mount/.sliceup-data/pgdata
                    
                    
                     chown -R postgres:postgres $mount/.sliceup-data/pgdata
                     mkdir /etc/systemd/system/postgresql-10.service.d
                     echo "[Service]" > /etc/systemd/system/postgresql-10.service.d/override.conf
                     echo "Environment=PGDATA=$mount/.sliceup-data/pgdata" >> /etc/systemd/system/postgresql-10.service.d/override.conf
                     systemctl daemon-reload
                     /usr/pgsql-10/bin/postgresql-10-setup initdb
                     systemctl enable postgresql-10
                     systemctl start postgresql-10
                    dbdir=$mount/.sliceup-data/pgdata
                fi

###If data mount is default e.g. $s=y

                if [ "$s" = "Y" ] || [ "$s" = "y" ]; then

                     /usr/pgsql-10/bin/postgresql-10-setup initdb
                        
                    
                     systemctl start postgresql-10
                     systemctl enable postgresql-10
                    dbdir=/var/lib/pgsql/10/data

                fi



#Finish Postgres Install

     ln -s /usr/pgsql-10/bin/pg_config /usr/sbin/pg_config
    sleep 10

#create variable requires config for sliceupdev


echo -e "\e[96m Config Postgres.  \e[39m"


su - postgres <<-'EOF'
     postgres psql -c "CREATE USER sliceup WITH PASSWORD '$psqlpass';"
     postgres psql -c "ALTER ROLE sliceup WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;"
     postgres psql -c "CREATE DATABASE sliceup"
     postgres psql sliceup < /opt/sliceup/executables/db_migration/sourcedb.sql
EOF


#Lock this down and standardize install

     sed -i "s/#listen_addresses.*/listen_addresses = '*'/" $dbdir/postgresql.conf
   

# take user entered IP addresses and create hba config
    for address in "${ipaddresses[@]}"
    do
        line="host    all             all             $address\/32            md5"
         sed -i "s/# IPv4 local connections:/# IPv4 local connections:\n$line/" $dbdir/pg_hba.conf
    done

    line="host    all             all             $masterip\/32            md5"
     sed -i "s/# IPv4 local connections:/# IPv4 local connections:\n$line/" $dbdir/pg_hba.conf
     sed -i 's/\(host  *all  *all  *127.0.0.1\/32  *\)ident/\1md5/' $dbdir/pg_hba.conf
     sed -i 's/\(host  *all  *all  *::1\/128  *\)ident/\1md5/' $dbdir/pg_hba.conf


    echo -e "\e[96m Install additonal supporting files.  \e[39m"

     systemctl restart postgresql-10
     yum install python-devel -y
     yum install python3-devel -y
     yum groupinstall 'Development Tools' -y
     yum install PyOpenGL libtool autoconf pkgconfig python-pillow qt-devel python-tools python-pyside python2-pyside python36-pyside qt4-devel PyQt4-devel qt-x11 -y
    # apt-get install build-essential autoconf libtool pkg-config python-opengl python-pil python-pyrex python-pyside.qtopengl idle-python2.7 qt4-dev-tools qt4-designer libqtgui4 libqtcore4 libqt4-xml libqt4-test libqt4-script libqt4-network libqt4-dbus python-qt4 python-qt4-gl libgle3 python-dev -y
     yum install python3-pip -y
     python3 -m pip install psycopg2
     python3 -m pip install requests
     python3 -m pip install PrettyTable
     python3 -m pip install selenium
     python3 -m pip install kafka-python


    echo -e "\e[96m Replace variable information in configs  \e[39m"


#Update kafka Master IP
     sed -i "s/{MASTER_IP}/$masterip/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-1.properties
     sed -i "s/{MASTER_IP}/$masterip/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-2.properties
     sed -i "s/{MASTER_IP}/$masterip/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-3.properties
     sed -i "s/{MASTER_IP}/$masterip/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-4.properties

#If non default DB store e.g. $s=n, then configure new kafka log file location


	     if [ "$s" = "N" ] || [ "$s" = "n" ]; then


		  #set kafka directory and escape / using //
		  kafkadir1=\\$mount\\/.sliceup-data\\/kafka\\/broker-1
		  kafkadir2=\\$mount\\/.sliceup-data\\/kafka\\/broker-2
		  kafkadir3=\\$mount\\/.sliceup-data\\/kafka\\/broker-3
		  kafkadir4=\\$mount\\/.sliceup-data\\/kafka\\/broker-4


		   sed -i "s/log.dirs=\/tmp\/kafka-logs-1/log.dirs=$kafkadir1/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-1.properties
		   sed -i "s/log.dirs=\/tmp\/kafka-logs-2/log.dirs=$kafkadir2/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-2.properties
		   sed -i "s/log.dirs=\/tmp\/kafka-logs-3/log.dirs=$kafkadir3/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-3.properties
		   sed -i "s/log.dirs=\/tmp\/kafka-logs-4/log.dirs=$kafkadir4/" /opt/sliceup/executables/kafka_2.12-2.4.1/config/server-4.properties

	    fi



# Ensure Permissions
    cuser=$(whoami)
     chown -R $cuser /opt/sliceup

#Replace {MASTER_IP} to executables/vector/vector.toml
     sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/vector/vector.toml
     sed -i "s/{RECEIVING_PORT}/$port/g" /opt/sliceup/executables/vector/vector.toml

        
#Enable vector to run on port lower than 1024
     setcap 'cap_net_bind_service=+ep' /usr/bin/vector


#Replace {MASTER_IP} in executables/flink-1.10.0/conf/flink-conf.yaml
     sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/flink-1.10.0/conf/flink-conf.yaml
       

#Replace {MASTER_IP} in executables/conf.ini
     sed -i "s/{MASTER_IP}/$masterip/g" /opt/sliceup/executables/conf.ini

#Replace Postgres password
     sed -i "s/{PSQL_PASS}/$psqlpass/" /opt/sliceup/executables/conf.ini

    
#Replace {WORKER_IPS} in executables/flink-1.10.0/conf/slaves with list of worker ips
    # The current file is blank so adding marker
    echo "" > /opt/sliceup/executables/flink-1.10.0/conf/slaves

#Replace Grafana sed
     sed -i "s/{MASTER_IP}/$masterip/" san.cnf

       
#Grafana Install
    echo -e "\e[96m Installing Grafana.  \e[39m"
     yum install wget shadow-utils fontconfig freetype libfreetype.so.6 libfontconfig.so.1 libstdc++.so.6 -y
    wget https://dl.grafana.com/oss/release/grafana-7.0.4-1.x86_64.rpm
     yum install grafana-7.0.4-1.x86_64.rpm -y

#Grafana Create Cert
    openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout /opt/sliceup/ssl/key.pem -out /opt/sliceup/ssl/cert.pem -config san.cnf
     chown -R $cuser:grafana /opt/sliceup/ssl
    chmod 644 /opt/sliceup/ssl/*

#Grafana change and move files

     sed -i "s/;protocol = http/protocol = https/" /etc/grafana/grafana.ini
     sed -i "s/;http_addr =/http_addr = 0.0.0.0/" /etc/grafana/grafana.ini
     sed -i "s/;http_port = 3000/http_port = 3000/" //etc/grafana/grafana.ini
     sed -i "s/;cert_file =/cert_file = \/opt\/sliceup\/ssl\/cert.pem/" /etc/grafana/grafana.ini
     sed -i "s/;cert_key =/cert_key = \/opt\/sliceup\/ssl\/key.pem/" /etc/grafana/grafana.ini


     sed -i "s/psqlpass/$psqlpass/g" slicedatasource.yaml
     mv sliceupdashboards/*.* /opt/sliceup/dashboards/
     mv sliceprov.yaml /etc/grafana/provisioning/dashboards
     mv slicedatasource.yaml /etc/grafana/provisioning/datasources

    

####Begin Prime Start#####
    echo -e "\e[96m Installation is complete. Starting Prime Service.  \e[39m"
    sleep 2

###################Starting the Services#######################3
#  Grafana Start
     /bin/systemctl daemon-reload
     /bin/systemctl enable grafana-server
     /bin/systemctl start grafana-server

     yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
   
    sleep 2
   
     yum install jq -y

     grafana-cli plugins install magnesium-wordcloud-panel
    sleep 3
     service grafana-server restart
    sleep 3

     /bin/systemctl stop grafana-server
    sleep 5
     /bin/systemctl start grafana-server
    sleep 5
    id=$(curl -k -X GET -H "Content-Type: application/json" https://admin:admin@127.0.0.1:3000/api/dashboards/uid/wf5pdkHNa | jq .dashboard.id)
    echo -e "\e[96m Dashboard ID is $id \e[39m"
    curl -k -X PUT -H "Content-Type: application/json" -d '{"theme": "", "homeDashboardId": '$id', "timezone": ""}' https://admin:admin@127.0.0.1:3000/api/org/preferences

    echo -e "\e[96m Grafana installed successfully. \e[39m"
    sleep 2

#Enable service at startup
    echo -e "\e[96m Enable SlicePrime service  \e[39m"
     systemctl enable slicemaster
    echo -e "\e[96m Start SlicePrime service  \e[39m"
     systemctl start slicemaster
    echo -e "\e[96m SlicePrime service started. \e[39m"
