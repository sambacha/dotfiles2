#!/bin/sh

echo "Syncing submodules..."
git submodule sync --recursive && git submodule update --init --recursive
git submodule foreach --recursive git clean -ffdx
sleep 1
echo "Setting up Bash PreExec..."
chmod +x extensions/bash-preexec/bash-preexec.sh
cp extensions/bash-preexec/bash-preexec.sh ~/.bsh-preexec.sh
echo '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh' >> ~/.bash_profile

