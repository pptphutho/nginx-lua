#!/bin/bash
# shellcheck disable=SC1091

source supported_versions

function docker_tag_exists() {
    curl --silent -f -lSL "https://index.docker.io/v1/repositories/$1/tags/$2" > /dev/null
    echo $?
}

function docker_push() {
    TAG=$1
    docker push fabiocicerchia/nginx-lua:$TAG
    if [ $? -ne 0 ]; then
        docker push fabiocicerchia/nginx-lua:$TAG
    fi
}

function push() {
    NGINX_VER=$1
    OS=$2
    OS_VER=$3
    VER_TAGS=$4
    OS_TAGS=$5
    DEFAULT=$6

    MAJOR=$(echo "$NGINX_VER" | cut -d '.' -f 1)
    MINOR="$MAJOR".$(echo "$NGINX_VER" | cut -d '.' -f 2)
    PATCH="$NGINX_VER"

    if [ "$FORCE" == "0" ]; then
        if [ "$(docker_tag_exists fabiocicerchia/nginx-lua "$PATCH-$OS$OS_VER")" == "0" ]; then
            return
        fi
    fi

    [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$MAJOR-$OS$OS_VER" | wc -l) -ne 0 ]] && docker_push "$MAJOR-$OS$OS_VER"
    [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$MINOR-$OS$OS_VER" | wc -l) -ne 0 ]] && docker_push "$MINOR-$OS$OS_VER"
    [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$PATCH-$OS$OS_VER" | wc -l) -ne 0 ]] && docker_push "$PATCH-$OS$OS_VER"

    if [ "$VER_TAGS$OS_TAGS$DEFAULT" == "111" ]; then
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$MAJOR" | wc -l) -ne 0 ]] && docker_push "$MAJOR"
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$MINOR" | wc -l) -ne 0 ]] && docker_push "$MINOR"
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$PATCH" | wc -l) -ne 0 ]] && docker_push "$PATCH"
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:latest | wc -l) -ne 0 ]] && docker push fabiocicerchia/nginx-lua:latest
    fi

    if [ "$VER_TAGS$OS_TAGS" == "11" ]; then
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$OS" | wc -l) -ne 0 ]] && docker_push "$OS"
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$MAJOR-$OS" | wc -l) -ne 0 ]] && docker_push "$MAJOR-$OS"
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$MAJOR-$OS$OS_VER" | wc -l) -ne 0 ]] && docker_push "$MAJOR-$OS$OS_VER"
    fi

    if [ "$OS_TAGS" == "1" ]; then
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$MINOR-$OS" | wc -l) -ne 0 ]] && docker_push "$MINOR-$OS"
        [[ $(docker image ls -q fabiocicerchia/nginx-lua:"$PATCH-$OS" | wc -l) -ne 0 ]] && docker_push "$PATCH-$OS"
    fi
}

set -eux

OS=$1
FORCE=0
if [ "$2" == "1" ]; then
    FORCE=1
fi
VERSIONS=()
if [ "$OS" == "alpine" ]; then VERSIONS=("${ALPINE[@]}")
elif [ "$OS" == "amazonlinux" ]; then VERSIONS=("${AMAZONLINUX[@]}")
elif [ "$OS" == "centos" ]; then VERSIONS=("${CENTOS[@]}")
elif [ "$OS" == "debian" ]; then VERSIONS=("${DEBIAN[@]}")
elif [ "$OS" == "fedora" ]; then VERSIONS=("${FEDORA[@]}")
elif [ "$OS" == "ubuntu" ]; then VERSIONS=("${UBUNTU[@]}")
fi

NLEN=${#NGINX[@]}
for (( I=0; I<NLEN; I++ )); do
    NGINX_VER="${NGINX[$I]}"

    VER_TAGS=0
    if [ "$((I+1))" == "$NLEN" ]; then
        VER_TAGS=1
    fi

    # Default image is Alpine
    DEFAULT=0
    if [ "$OS" == "alpine" ]; then DEFAULT=1; fi

    DLEN=${#VERSIONS[@]}
    for (( J=0; J<DLEN; J++ )); do
        OS_VER="${VERSIONS[$J]}"
        OS_TAGS=0
        if [ "$((J+1))" == "$DLEN" ]; then
            OS_TAGS=1
        fi
        push "$NGINX_VER" "$OS" "$OS_VER" $VER_TAGS $OS_TAGS $DEFAULT
    done

done
