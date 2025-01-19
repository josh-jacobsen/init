#!/usr/bin/env fish

function setup_github_ssh
    # Check if SSH key already exists
    if test -f ~/.ssh/id_ed25519
        echo "SSH key already exists at ~/.ssh/id_ed25519"
        read -l -P "Do you want to create a new one? [y/N] " confirm
        if test "$confirm" != "y" -a "$confirm" != "Y"
            echo "Keeping existing SSH key"
            return
        end
    end

    # Get GitHub email
    read -l -P "Enter your GitHub email: " github_email
    
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    
    # Generate SSH key
    echo "Generating new SSH key..."
    ssh-keygen -t ed25519 -C "$github_email" -f ~/.ssh/id_ed25519
    
    # Start ssh-agent
    eval (ssh-agent -c)
    
    # Add SSH key to ssh-agent
    ssh-add ~/.ssh/id_ed25519
    
    # Add ssh-agent startup to fish config if not already present
    set config_file ~/.config/fish/config.fish
    if not test -f $config_file
        mkdir -p ~/.config/fish
        touch $config_file
    end
    
    if not grep -q "eval (ssh-agent -c)" $config_file
        echo "" >> $config_file
        echo "# Start SSH agent" >> $config_file
        echo "eval (ssh-agent -c) >/dev/null" >> $config_file
    end
    
    # Copy public key to clipboard
    pbcopy < ~/.ssh/id_ed25519.pub
    
    echo "
SSH key has been:
1. Generated as ~/.ssh/id_ed25519
2. Added to ssh-agent
3. Copied to your clipboard

Next steps:
1. Go to GitHub Settings: https://github.com/settings/ssh/new
2. Add a new SSH key
3. Paste the key from your clipboard
4. Test with: ssh -T git@github.com
"
end

# Run the function
setup_github_ssh
