#!/usr/bin/env bash
set -e

echo "🔗 Vinculando Dotfiles..."

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.cache/dotfiles-backup/$(date +'%Y%m%d_%H%M%S')"

mkdir -p "$CONFIG_DIR"

# Pastas da ~/.config
CONFIG_FOLDERS=(
    # Ambiente Sway / Wayland
    "sway"
    "swaync"
    "waybar"
    "wofi"
    "kitty"
    "foot"
    "kanshi"
    "nwg-displays"
    "gsimplecal"
    "hypr"
    # Editores, Shell e CLI
    "nvim"
    "yazi"
    "btop"
    "bottom"
    "micro"
    "fish"
)

# Arquivos da raiz da $HOME (formato "arquivo_na_home:arquivo_no_dotfiles")
HOME_FILES=(
    ".zshrc:zshrc"
    ".p10k.zsh:p10k.zsh"
    ".gitconfig:gitconfig"
)

for folder in "${CONFIG_FOLDERS[@]}"; do
    TARGET="$CONFIG_DIR/$folder"
    SOURCE="$DOTFILES_DIR/$folder"

    if [ -d "$SOURCE" ]; then
        if [ -L "$TARGET" ] && [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
            echo "  ✅ $folder já vinculado."
            continue
        fi
        if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
            mkdir -p "$BACKUP_DIR"
            mv "$TARGET" "$BACKUP_DIR/$folder"
            echo "  🛡️  Backup de $TARGET salvo em $BACKUP_DIR/$folder"
        fi
        ln -s "$SOURCE" "$TARGET"
        echo "  🔗 Link criado para: $folder"
    fi
done

for entry in "${HOME_FILES[@]}"; do
    HOME_NAME="${entry%%:*}"
    REPO_NAME="${entry##*:}"
    TARGET="$HOME/$HOME_NAME"
    SOURCE="$DOTFILES_DIR/$REPO_NAME"

    if [ -f "$SOURCE" ]; then
        if [ -L "$TARGET" ] && [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
            echo "  ✅ $HOME_NAME já vinculado."
            continue
        fi
        if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
            mkdir -p "$BACKUP_DIR"
            mv "$TARGET" "$BACKUP_DIR/$HOME_NAME"
            echo "  🛡️  Backup de $TARGET salvo em $BACKUP_DIR/$HOME_NAME"
        fi
        ln -s "$SOURCE" "$TARGET"
        echo "  🔗 Link criado para: $HOME_NAME"
    fi
done

echo "✅ Concluído!"
