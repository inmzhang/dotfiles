if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.bak
fi

git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
