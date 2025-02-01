#!/usr/bin/env fish
function setup_github_ssh
    # Define SSH key path variable
    set ssh_key_path ~/.ssh/id_ed25519

    # Check if SSH key already exists
    if test -f $ssh_key_path
        echo "SSH key already exists at $ssh_key_path"
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
    ssh-keygen -t ed25519 -C "$github_email" -f $ssh_key_path
    
    # Start ssh-agent
    eval (ssh-agent -c)
    
    # Add SSH key to ssh-agent
    ssh-add $ssh_key_path
    
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
    pbcopy < $ssh_key_path.pub
    
    echo "
SSH key has been:
1. Generated as $ssh_key_path
2. Added to ssh-agent
3. Copied to your clipboard
Next steps:
1. Go to GitHub Settings: https://github.com/settings/ssh/new
2. Add a new SSH key
3. Paste the key from your clipboard
4. Test with: ssh -T git@github.com
5. If you encounter the error: git@github.com: Permission denied (publickey), add the key to the agent with: `ssh-add $ssh_key_path` 
"
end
# Run the function
setup_github_ssh
