#!/bin/bash
#*----------------------------------------------------------------------------*
#* NAME: create.sh
#*
#* DESCRIPTION:
#* Create OCI images and distroboxen
#* Pass --prune as the first arg to stop containers and perform system prune
#*----------------------------------------------------------------------------*

# CM_OPTS="BUILDKIT_PROGRESS=plain"
CM_OPTS=""

#BASE_IMGS=(fedora41-dev-base fedora41-dotnet fedora41-python fedora41-go fedora41-zig)
BASE_IMGS=(fedora41-dev-base fedora41-python fedora41-dotnet)

# Note these each must match one of BASE_IMGS adding '-dx' suffix
#DX_IMGS=(fedora41-dotnet-dx fedora41-go-dx fedora41-python-dx fedora41-zig-dx)
DX_IMGS=(fedora41-dotnet-dx fedora41-python-dx)

IMG_NAMES=(${BASE_IMGS[@]} ${DX_IMGS[@]})

ASSEMBLE_IMG_IDXS=(0 1)  # control which to assemble

export DBX_CONTAINER_MANAGER=docker

PRUNE=${1:-''}

#*----------------------------------------------------------------------------*
function _logbar
{
    declare -r bar='#* ----------------------------------------------------------------------'

    echo $bar
    echo $*
    echo $bar
}
#*----------------------------------------------------------------------------*
function assemble_distrobox
{
    local container_name=$1

    echo DBX_CONTAINER_ALWAYS_PULL=0 distrobox assemble create --replace --name ${container_name}
    DBX_CONTAINER_ALWAYS_PULL=0 distrobox assemble create --replace --name ${container_name}
}
#*----------------------------------------------------------------------------*
function clean_imgs
{
    local length=${#BASE_IMGS[@]}
    for ((i=length-1; i>=0; i--))
    do
        local img=${BASE_IMGS[i]}
        _logbar Cleaning ${img} ...

        ${DBX_CONTAINER_MANAGER} rmi -f ${img}

        _logbar Cleaning ${img} ... done.
    done

    ${DBX_CONTAINER_MANAGER} image prune -f
}
#*----------------------------------------------------------------------------*
function create_img
{
    local name=$1

    if [ ${did_prune} -ne 1 ]
    then
        ${DBX_CONTAINER_MANAGER} stop ${name}
        ${DBX_CONTAINER_MANAGER} rm -f --volumes ${name}
        ${DBX_CONTAINER_MANAGER} rmi -f ${name}
    fi

    _logbar Creating ${name} ...

    local build_args=""
    local cf_suffix=${name}
    if [[ "${name}" =~ "-dx"$ ]]
    then
        build_args="--build-arg USER=$USER"
        build_args+=" --build-arg UID=`id -u $USER`"
        build_args+=" --build-arg GID=`id -g $USER`"
        build_args+=" --build-arg IMG=${name%-dx}"
        cf_suffix="img-dx"
    fi

    echo ${CM_OPTS} ${DBX_CONTAINER_MANAGER} buildx build -f Containerfile.${cf_suffix} -t ${name}:latest ${build_args} .
    ${CM_OPTS} ${DBX_CONTAINER_MANAGER} buildx build -f Containerfile.${cf_suffix} -t ${name}:latest ${build_args} .

    _logbar Creating ${name} ... done.
}
#*----------------------------------------------------------------------------*
function do_prune
{
    _logbar Shutting down and pruning ...

    for c in $(${DBX_CONTAINER_MANAGER} ps --format json | jq -r '.ID')
    do
        ${DBX_CONTAINER_MANAGER} stop $c
    done

    ${DBX_CONTAINER_MANAGER} system prune -af --volumes

    _logbar Shutting down and pruning ... done.
}
#*----------------------------------------------------------------------------*
function show_imgs_layers
{
    local imgs=$(${DBX_CONTAINER_MANAGER} image ls --format json | jq -r .Repository)
    local img
    for img in ${imgs}
    do
        _logbar ${img}
        ${DBX_CONTAINER_MANAGER} inspect --format json ${img}:latest | jq -r .[0].RootFS.Layers
    done
}
#*----------------------------------------------------------------------------*

# Tear down
did_prune=0
if [ "${PRUNE}" = '--prune' ]
then
    did_prune=1
    do_prune
fi


# Make sure `lets` is installed first ... needed on host and containers
# curl --proto '=https' --tlsv1.2 -sSf https://lets-cli.org/install.sh | sh -s -- -b ~/.local/bin


# Create images
for name in ${IMG_NAMES[@]}
do
    create_img ${name}
done


# allow system to coallesce
sleep 5


# assemble
for idx in ${ASSEMBLE_IMG_IDXS[@]}
do
    assemble_distrobox ${DX_IMGS[${idx}]}
done

# Clean up unneeded images
clean_imgs

#*----------------------------------------------------------------------------*
