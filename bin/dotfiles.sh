#!/bin/bash
set -e

# Paths
CONFIG_DIR="$HOME/.config/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"
SSH_DIR="$HOME/.ssh"

# Install Ansible
if ! [ -x "$(command -v ansible)" ]; then
  sudo pacman -S ansible --noconfirm
fi

# Generate SSH keys
if ! [[ -f "$SSH_DIR/authorized_keys" ]]; then
  mkdir -p "$SSH_DIR"

  chmod 700 "$SSH_DIR"

  ssh-keygen -b 4096 -t rsa -f "$SSH_DIR/id_rsa" -N "" -C "$USER@$HOSTNAME"

  cat "$SSH_DIR/id_rsa.pub" >> "$SSH_DIR/authorized_keys"
fi

# Clone repository
if ! [[ -d "$DOTFILES_DIR" ]]; then
  git clone "https://github.com/gabriel-suela/ansible-dotfiles.git" "$DOTFILES_DIR"
else
  git -C "$DOTFILES_DIR" pull
fi

# Create path
cd "$DOTFILES_DIR"

export LC_ALL="C.UTF-8"

# Update Galaxy
ansible-galaxy install -r requirements.yml

# Run playbook
if [[ -f "$CONFIG_DIR/vault-password.txt" ]]; then
  ansible-playbook --diff --extra-vars "@$CONFIG_DIR/values.yaml" --vault-password-file "$CONFIG_DIR/vault-password.txt" "$DOTFILES_DIR/main.yaml" "$@"
else
  ansible-playbook --diff --extra-vars "@$CONFIG_DIR/values.yaml" "$DOTFILES_DIR/main.yaml" "$@"
fi
