#!/bin/bash

	 echo -e "\e[96m ALL WORKER nodes should be installed before the Prime node is installed. \e[39m"
	 echo -e "\e[96m If this is the Prime node and you have not installed the worker nodes first, please CTL C and install ALL worker nodes first \e[39m"
	 echo -e "\e[96m Is this the Prime node or a Worker node? \e[39m"

        echo -e "\e[96m Type \"P\" for Prime or  or \"W\" for Worker and press Enter\e[39m"
echo " "
            read s
	            if [ "$s" = "P" ] || [ "$s" = "p" ]; then

                     echo -e "\e[96m You have selected Prime \e[39m"
		     echo -e "\e[96m If this is correct press Enter else CTL C \e[39m"
                    read nill
                    ./primenodeinstall.sh

	            elif [ "$s" = "W" ] || [ "$s" = "w" ]; then
	             
	                   echo -e "\e[96m You have selected Worker \e[39m"
		           echo -e "\e[96m If this is correct, press Enter else CTL C \e[39m"
	             read nill
		    ./remotenodeinstall.sh 
	             	else
	                    echo "Invalid selection. Run the script again"
	             exit
	            fi
