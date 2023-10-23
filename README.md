# dotfiles

dotfiles managed by [yadm](https://github.com/TheLocehiliosan/yadm)

## Usage

> Currently, this repo does not include bootstrap procedure, you need to install the necessary packages by yourself.

1. Install yadm

```shell
case "${OSTYPE:?}" in
  linux*)   yay -S yadm ;;
  darwin*)  brew install yadm ;;
esac
```

2. Clone

```shell
yadm clone git@github.com:inmzhang/dotfiles.git
```
