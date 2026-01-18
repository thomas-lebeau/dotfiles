1. install yadm
```bash
# Manual install because brew is not available yet
curl -fLo /usr/local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm && chmod a+x /usr/local/bin/yadm

# Clone dotfiles
yadm clone https://github.com/thomas-lebeau/dotfiles.git
```

2. import iterm keymap preferences
  - iterm2 > Keys > Key Bindings > Presets > Import... 
  - select file in `~/.config/iterm2/key-mappings.itermkeymap`
