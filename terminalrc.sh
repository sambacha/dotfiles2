# vi: ft=bash
# $SHELL.rc options
shopt -s dirspell globstar histappend histverify nocaseglob nullglob

for config in "$XDG_CONFIG_HOME"/bashrc.d/*.bash{,.local}; do
  # shellcheck disable=SC1090
  test -r "$config" && . "$config"
done
