#!/bin/bash

#Nos logeamos como el nuevo usuario
sudo mkdir -p /etc/rbac/p_keys/$1
sudo chown -R $1:root /etc/rbac/p_keys/$1
sudo su $1 <<EOF
ssh-keygen -t rsa -N "" -f /tmp/id_rsa &> /dev/null
EOF
#Mandamos la privada al cliente
echo -e "to: rbacassistant@gmail.com\nsubject: SSH Key\n" | (cat - && uuencode /tmp/id_rsa id_rsa) | ssmtp rbacassistant@gmail.com
#Mandamos la privada al cliente

#Guardamos la publica en la carpeta ssh del usuario en el servidor y la privada en p_keys
FILE=/etc/rbac/ssh/$1/authorized_keys
if ! [ -f "$FILE" ]; then
	sudo mkdir -p /etc/rbac/ssh/$1/
	sudo touch $FILE
fi
sudo mv /tmp/id_rsa.pub  $FILE
sudo mv /tmp/id_rsa /etc/rbac/p_keys/$1/

#Ponemos al usuario como dueño y cambiamos permisos
sudo chown $1:root $FILE
sudo chmod 600 $FILE
