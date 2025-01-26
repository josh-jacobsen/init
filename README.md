# Setting up a new machine 


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
9. Brew install build dependancies:
    ```
    brew install ninja cmake gettext curl ripgrep fzf 
   ```

10. Install node
    ```
    asdf plugin add nodejs
    asdf install nodejs 20.18.1
    ```
9. Install neovim:
    ```
    git clone https://github.com/neovim/neovim
    cd neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    ```

To change which version of neovim is built, checkout the branch. Run

      ```
      rm -rf build/
      make distclean
      ```
   Then the same commands as above to build it 

10. Install tooling via Brew:
    ```
    brew install stow lazygit gh awscli tmux
    brew install --cask aws-vault
    brew install --cask raycast
    brew install --cask visual-studio-code
    brew install --cask shottr
    brew install --cask ghostty
    brew install --cask nikitabobko/tap/aerospace
    brew install --cask 1password
    brew install --cask lastpass
    ```

11. Install tmux plugins like catpuchin from the repo (instaructions there)
    
11. ~Set up nerd font for Fish via Fisher: `curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher`~

12. Font: brew install --cask font-fira-code-nerd-font
    
11. Set up SSH keys ([script](https://github.com/josh-jacobsen/init/blob/main/setup_github_ssh.fish))

12. Download firefox and the tree style tabs extension
13. Password managers (1Password)


