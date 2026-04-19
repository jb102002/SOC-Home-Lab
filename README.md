      _          _                 _           _           
     | |        | |               | |         | |          
     | |__   ___| |__   ___   ___ | |__   ___ | |__  _ __  
     | '_ \ / _ \ '_ \ / _ \ / _ \| '_ \ / _ \| '_ \| '_ \ 
     | | | |  __/ |_) | (_) | (_) | |_) | (_) | | | | | | |
     |_| |_|\___|_.__/ \___/ \___/|_.__/ \___/|_| |_|_| |_|
            J a c o b ' s   S O C   H o m e   L a b
            
            
Project Summary 



SSH into Splunk Server

ssh -i "C:\Users\user\AWS SOC Lab Terra\example.pem" ubuntu@1.2.3.4

NOTE: Before using SSH to connect to Splunk Instance you make have to change the file permissions of your .pem file where you stored your SHH key pair

 Store the path in a variable to make it easier
$keyPath = "C:\Users\user\AWS SOC Lab Terra\example.pem"

 Remove all inherited permissions
icacls $keyPath /inheritance:r

 Remove the BUILTIN\Users group access
icacls $keyPath /remove "BUILTIN\Users"

 Remove EVERYONE access just in case
icacls $keyPath /remove "Everyone"

 Give only your user account full access
icacls $keyPath /grant:r "user:F"
