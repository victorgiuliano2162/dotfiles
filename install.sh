#!/usr/bin/env bash
set -e

echo "Vinculando Dotfiles..."

mkdir -p ~/.config
DOTFILES_DIR="$HOME/dotfiles"

# Pastas da ~/.config
CONFIG_FOLDERS=("sway" "waybar" "kitty" "gtk-3.0")

for folder in "${CONFIG_FOLDERS[@]}"; do
    TARGET="$HOME/.config/$folder"
    SOURCE="$DOTFILES_DIR/$folder"

    if [ -d "$SOURCE" ]; then
        if [ -d "$TARGET" ] && [ ! -L "$TARGET" ]; then
            mv "$TARGET" "$TARGET.bak"
        fi
        ln -sf "$SOURCE" "$TARGET"
        echo "Link criado para: $folder"
    fi
done

# Arquivo .zshrc na raiz da $HOME
if [ -f "$DOTFILES_DIR/zshrc" ]; then
    ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
    echo "Link criado para: .zshrc"
fi

echo "Concluído!"
