#!/bin/sh


# into an awesome development machine.


fancy_echo() {
  local fmt="$1"; shift


  # shellcheck disable=SC2059
  printf "\\n$fmt\\n" "$@"
}


append_to_bashrc() {
  local text="$1" bashrc
  local skip_new_line="${2:-0}"


  if [ -w "$HOME/.bashrc.local" ]; then
    bashrc="$HOME/.bashrc.local"
  else
    bashrc="$HOME/.bashrc"
  fi


  if ! grep -Fqs "$text" "$bashrc"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\\n" "$text" >> "$bashrc"
    else
      printf "\\n%s\\n" "$text" >> "$bashrc"
    fi
  fi
}


# shellcheck disable=SC2154
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT


set -e


if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi


if [ ! -f "$HOME/.bashrc" ]; then
  touch "$HOME/.bashrc"
fi


# shellcheck disable=SC2016
append_to_bashrc 'export PATH="$HOME/.bin:$PATH"'


HOMEBREW_PREFIX="/usr/local"


if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" /usr/local
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi


update_shell() {
  local shell_path;
  shell_path="$(command -v bash)"


  fancy_echo "Changing your shell to bash ..."
  if ! grep "$shell_path" /etc/shells > /dev/null 2>&1 ; then
    fancy_echo "Adding '$shell_path' to /etc/shells"
    sudo sh -c "echo $shell_path >> /etc/shells"
  fi
  sudo chsh -s "$shell_path" "$USER"
}


case "$SHELL" in
  */bash)
    if [ "$(command -v bash)" != '/usr/local/bin/bash' ] ; then
      update_shell
    fi
    ;;
  *)
    update_shell
    ;;
esac


gem_install_or_update() {
  if gem list "$1" --installed > /dev/null; then
    gem update "$@"
  else
    gem install "$@"
  fi
}


if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
    /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"


    append_to_bashrc '# recommended by brew doctor'


    # shellcheck disable=SC2016
    append_to_bashrc 'export PATH="/usr/local/bin:$PATH"' 1


    export PATH="/usr/local/bin:$PATH"
fi


if brew list | grep -Fq brew-cask; then
  fancy_echo "Uninstalling old Homebrew-Cask ..."
  brew uninstall --force brew-cask
fi

# # Databases
#brew "postgres", restart_service: :changed
#brew "redis", restart_service: :changed

fancy_echo "Updating Homebrew formulae ..."
brew update --force # https://github.com/Homebrew/brew/issues/1151
brew bundle --file=- <<EOF
tap "thoughtbot/formulae"
tap "homebrew/services"
tap "universal-ctags/universal-ctags"
tap "heroku/brew"

# Unix
brew "universal-ctags", args: ["HEAD"]
brew "git"
brew "openssl"
brew "rcm"
brew "reattach-to-user-namespace"

# GitHub
brew "gh"


# Programming language prerequisites and package managers
brew "libyaml" # should come after openssl
brew "coreutils"
brew "yarn"
cask "gpg-suite"
EOF


fancy_echo "Configuring asdf version manager ..."
if [ ! -d "$HOME/.asdf" ]; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.5.0
  append_to_bashrc "source $HOME/.asdf/asdf.sh" 1
fi


alias install_asdf_plugin=add_or_update_asdf_plugin
add_or_update_asdf_plugin() {
  local name="$1"
  local url="$2"


  if ! asdf plugin-list | grep -Fq "$name"; then
    asdf plugin-add "$name" "$url"
  else
    asdf plugin-update "$name"
  fi
}


# shellcheck disable=SC1090
source "$HOME/.asdf/asdf.sh"
add_or_update_asdf_plugin "ruby" "https://github.com/asdf-vm/asdf-ruby.git"
add_or_update_asdf_plugin "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git"


install_asdf_language() {
  local language="$1"
  local version
  version="$(asdf list-all "$language" | grep -v "[a-z]" | tail -1)"


  if ! asdf list "$language" | grep -Fq "$version"; then
    asdf install "$language" "$version"
    asdf global "$language" "$version"
  fi
}


fancy_echo "Installing latest Ruby ..."
install_asdf_language "ruby"
gem update --system
number_of_cores=$(sysctl -n hw.ncpu)
bundle config --global jobs $((number_of_cores - 1))


fancy_echo "Installing latest Node ..."
bash "$HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring"
install_asdf_language "nodejs"


if [ -f "$HOME/.dotfiles2.local" ]; then
  fancy_echo "Running your customizations from ~/.dotfiles2.local ..."
  # shellcheck disable=SC1090
  . "$HOME/.dotfiles2.local"
fi
