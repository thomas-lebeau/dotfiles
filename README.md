# dotfiles
Personal dotfiles managed with [yadm](https://yadm.io/).

## Setup
1. install git (if not already installed)

  ```bash
  apt install git
  ```

2. install yadm
  ```bash
  curl -fLo /usr/local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm && chmod a+x /usr/local/bin/yadm
  ```

3. Clone dotfiles
  ```bash
  yadm clone https://github.com/thomas-lebeau/dotfiles.git
  ```

## iTerm2 Key Mappings
To use the custom key mappings for iTerm2, follow these steps:

1. import iterm keymap preferences
  - iterm2 > Keys > Key Bindings > Presets > Import... 
  - select file in `~/.config/iterm2/key-mappings.itermkeymap`
