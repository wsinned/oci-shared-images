#!/bin/bash
#*----------------------------------------------------------------------------*
#* NAME: show_img_layers.sh
#*
#* DESCRIPTION:
#* Showe layers for defined images
#*----------------------------------------------------------------------------*

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
    local imgs=$(${DBX_CONTAINER_MANAGER} image ls --format json | jq -r '.Repository | select(. != "<none>")' | sort)
    local img
    for img in ${imgs}
    do
        _logbar ${img}
        ${DBX_CONTAINER_MANAGER} inspect --format json ${img}:latest | jq -r .[0].RootFS.Layers
    done
}
#*----------------------------------------------------------------------------*

show_imgs_layers

#*----------------------------------------------------------------------------*
