#!/bin/bash
#Lee los archivos de configuración y crea los grupos
#Fase 2: Crea las imágenes de cada grupo

for file in /etc/rbac/roles/*;do 
	groupname="$(basename $file | cut -f 1 -d '.')"
	echo "-----------------------------------------------------------------------------"
	echo "Adding group and Docker image: $groupname"

	#Definimos el entorno

	mkdir -p /data/tmp
	enviroment="/data/tmp"
	#rm -r $enviroment/*

	sudo rm -rf $enviroment/*
	#Leemos el archivo de configuracion
	FILE=/etc/rbac/roles/$groupname.conf
	comandos=$(sed -n '2p' < "$FILE" | awk -F [-] '{print $2}')

	#Creamos los directorios necesarios
	sudo mkdir -p ${enviroment}/{lib,bin,sbin,lib64,dev,proc,etc,usr} ${enviroment}/usr/{bin,sbin,lib}

	sudo mkdir -p $enviroment/home/
	sudo cp -r /etc/skel/. "$enviroment/home"

	sudo cp /etc/nsswitch.conf $enviroment/etc
	sudo cp -r /usr/lib $enviroment/usr/
	sudo cp -r /lib $enviroment
	sudo cp -r /lib64 $enviroment


	groupadd $groupname

	FILE=/etc/rbac/roles/$groupname.conf
	comandos=$(sed -n '2p' < "$FILE" | awk -F [-] '{print $2}')

	rm /var/lib/dpkg/lock
	rm /var/cache/apt/archives/lock
	for item in $comandos
	do
	echo "Installing $item ...."
	sudo apt-get install $item >> /dev/null
	file=/bin/${item}
	if [ -f "$file" ];then 
		sudo cp /bin/${item} $enviroment/bin
	else
		file=/sbin/${item}
		if [ -f "$file" ];then 
			sudo cp /sbin/${item} $enviroment/sbin
		else
			file=/usr/bin/${item}
			if [ -f "$file" ];then 
				sudo cp /usr/bin/${item} $enviroment/sbin
			fi
		fi
	fi
	done

	echo "Creating the compressed image for $groupname... That can take quite some time..."
	sudo debootstrap $enviroment $groupname > /dev/null

	echo "Creating the actual docker image for $groupname... That can take quite some time..."

	sudo tar -C $enviroment -c . | sudo docker import - $groupname

	logger -p local1.info "Nueva imagen "$groupname" añadida"


done
