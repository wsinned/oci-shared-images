# OCI Containers for distrobox and devcontainers

The contents of this dir are intended to be installed in `~/.local/distrobox/fedora`.

The main script is [`create.sh`](./create.sh). It will create all of the OCI images and assemble a distrobox.

If the `--prune` arg is passed as the first script parameter it will stop all running containers and perform a `docker system prune -af --volumes` command before getting started.

Another script, [`show_img_layers.sh`](./show_img_layers.sh) will show the layers of the built images as a means of showing layer reuse.
