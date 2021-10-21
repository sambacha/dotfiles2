sudo sed -ri 's/=.*/\L&/g; s/public$/public-share/; s/documents/docs/g; s/pictures/pics/g' /etc/xdg/user-dirs.defaults
xdg-user-dirs-update --force
