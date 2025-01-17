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
   
