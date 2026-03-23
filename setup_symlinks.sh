#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

ln -sfn $DIR/config/zshrc $HOME/.zshrc
ln -sfn $DIR/config/vimrc $HOME/.vimrc
ln -sfn $DIR/config/ssh $HOME/.ssh
ln -sfn $DIR/.gitconfig $HOME/.gitconfig
ln -sfn $DIR/config/gitconfig $HOME/.gitconfig
ln -sfn $DIR/config/nvim $HOME/.config/nvim
ln -sfn $DIR/config/nvim $HOME/.config/nvim
ln -sfn $DIR/config/lazygit $HOME/.config/lazygit
ln -sfn $DIR/config/Nextcloud $HOME/.config/Nextcloud

