#!/bin/bash
#*----------------------------------------------------------------------------*
#* NAME: show_img_layers.sh
#*
#* DESCRIPTION:
#* Showe layers for defined images
#*----------------------------------------------------------------------------*

if $(which yq >/dev/null 2>&1)
then
    true
else
    echo "$0 depends on yq - not found in path"
    exit 2
fi

export DBX_CONTAINER_MANAGER=docker

#*----------------------------------------------------------------------------*
function _logbar
{
    declare -r bar='#* ----------------------------------------------------------------------'

    echo $bar
    echo $*
    echo $bar
}
#*----------------------------------------------------------------------------*
function show_imgs_layers
{
    local imgs=$(${DBX_CONTAINER_MANAGER} image ls --format json | yq -p=j 'select(.Repository != "<none>") | (.Repository + ":" + .Tag)' | sed '/---/d' | sort)
    local img
    for img in ${imgs}
    do
        _logbar ${img}
        ${DBX_CONTAINER_MANAGER} inspect --format json ${img} | yq -P .[0].RootFS.Layers
    done
}
#*----------------------------------------------------------------------------*

show_imgs_layers

#*----------------------------------------------------------------------------*
