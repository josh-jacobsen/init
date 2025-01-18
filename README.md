# Setting up a new machine 

1. Download firefox and the tree style tabs extension
2. Password managers (1Password)
3. Install [Homebrew](https://brew.sh/) via the default Terminal 
4. Download shell ([Fish](https://fishshell.com/)) using Homebrew
5. Make Fish the default shell with:
   ```
    which fish (to get location)
    cat /etc/shells
    echo /opt/homebrew/bin/brew | sudo tee -a /etc/shells
    chsh -s /opt/homebrew/bin/brew
   ```
7. Point Fish at the Homebrew install (`fish_add_path /opt/homebrew/bin`)
8. Install package manager (asdf or rtx)
    ```
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
    Then add this line instead to your ~/.config/fish/config.fish
    source ~/.asdf/asdf.fish
    ```
9. Install neovim:
 Install build dependancies:
    ```
    brew install ninja cmake gettext curl

    ```
    ```
    git clone https://github.com/neovim/neovim
    cd neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
```
```

To change which version of neovim is built, checkout the branch. Run

```
rm -rf build/
make distclean
```
Then the same commands as above to build it 

10. Install terminal (Ghostty) 
