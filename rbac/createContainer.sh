#!/bin/bash
if [ -z $PAM_USER ]; then
	user=$1
else
	user=$PAM_USER
fi
if [ "$PAM_TYPE" = "close_session" ]; then
	docker stop $user
	logger -p local1.info "Contenedor del usuario "$PAM_USER" parado"

	exit
fi
rol=$(echo `groups $user` | awk -F " " '{print $3}')
IMAGEN=$(docker images | grep $rol | awk -F " " '{print $3}')
FILE=/etc/rbac/roles/$rol.conf
fisica=$(sed -n '5p' < "$FILE" | awk -F [-] '{print $2}')
swap=$(sed -n '6p' < "$FILE" | awk -F [-] '{print $2}')
cantidad=$(sed -n '7p' < "$FILE" | awk -F [-] '{print $2}')
importancia=$(sed -n '8p' < "$FILE" | awk -F [-] '{print $2}')
num=$(grep -c ^processor /proc/cpuinfo)
op=$(echo "scale=2; $num * $cantidad" | bc)
cpus=$(echo "scale=2; $op / 2" | bc)
red=$(sed -n '10p' < "$FILE" | awk -F [-] '{print $2}')
id=$(id -u $user)
#Creamos el contenedor en base a su imagen
opt="--memory="$fisica" --memory-swap="$swap" --cpus="$cpus" --cpu-shares "$importancia" --user $id"
#Comprobamos que exista el container
if [ "$(docker ps -aq -f status=exited -f name=$user)" ]; then
	echo "Arrancando container..."
	logger -p local1.info "Contenedor del usuario "$PAM_USER" iniciado"

	docker start $user
#Sino, lo creamos
else
	if [ $(docker ps -q -f name=$user)  ]; then
		echo "Container ya arrancado!"
		exit
	fi	
	echo "Creando container..."
	logger -p local1.info "Contenedor del usuario "$PAM_USER" creado e iniciado"

	case $rol in
		"datastore")
			#Ni red ni puertos abiertos
			docker run -itd --name $user $opt $IMAGEN /bin/bash
			;;
		"visitor")
			#Creamos una red para cada visitor, si no existe ya, con el nombre del usuario y nos conectamos
			docker network inspect $red &>/dev/null || docker network create --driver bridge --subnet 172.24.0.0/16 $red
			#Arranca el container, conectandose a la red creada
			docker run -itd $opt --name $user --network=$red $opt $IMAGEN /bin/bash
			;;
		"basic" | "medium" | "advanced")
			echo "Creando red..."
			docker network inspect $red &>/dev/null || docker network create --driver bridge --subnet 172.25.0.0/16 $red

			puerto=$(sed -n '9p' < "$FILE" | awk -F [-] '{print $2}')
		
			docker run -itd $opt --name $user --network=$red --expose $puerto $IMAGEN /bin/bash
			;;
	esac
fi
