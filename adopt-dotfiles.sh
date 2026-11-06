#!/usr/bin/env bash
set -e

echo "📦 Adotando e sincronizando configurações para o diretório dotfiles..."

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.cache/dotfiles-backup/$(date +'%Y%m%d_%H%M%S')"

# Pastas da ~/.config gerenciadas pelo repositório
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

mkdir -p "$DOTFILES_DIR" "$CONFIG_DIR"

for folder in "${CONFIG_FOLDERS[@]}"; do
    TARGET="$CONFIG_DIR/$folder"
    SOURCE="$DOTFILES_DIR/$folder"

    echo "Processando ~/.config/$folder..."

    # Caso 1: ~/.config/pasta já é um link simbólico
    if [ -L "$TARGET" ]; then
        if [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
            echo "  ✅ Link já existe e aponta para $SOURCE"
        else
            mkdir -p "$BACKUP_DIR"
            mv "$TARGET" "$BACKUP_DIR/${folder}.symlink.bak"
            ln -s "$SOURCE" "$TARGET"
            echo "  🔗 Link atualizado para $SOURCE"
        fi
        continue
    fi

    # Caso 2: ~/.config/pasta é um diretório real
    if [ -d "$TARGET" ]; then
        # Se houver um repositório .git aninhado dentro da pasta, faz backup dele
        if [ -d "$TARGET/.git" ]; then
            mkdir -p "$BACKUP_DIR"
            echo "  ⚠️  Movendo .git aninhado de $TARGET/.git para $BACKUP_DIR/${folder}.git.bak"
            mv "$TARGET/.git" "$BACKUP_DIR/${folder}.git.bak"
        fi

        if [ -d "$SOURCE" ]; then
            echo "  🔄 Atualizando $SOURCE com o conteúdo mais recente de $TARGET"
            cp -a "$TARGET/." "$SOURCE/"
            mkdir -p "$BACKUP_DIR"
            mv "$TARGET" "$BACKUP_DIR/$folder"
        else
            echo "  📂 Movendo $TARGET para $SOURCE"
            mv "$TARGET" "$SOURCE"
        fi

        ln -s "$SOURCE" "$TARGET"
        echo "  🔗 Link criado: $TARGET -> $SOURCE"
        continue
    fi

    # Caso 3: ~/.config/pasta não existe, mas já existe em ~/dotfiles (ex.: foot)
    if [ -d "$SOURCE" ]; then
        ln -s "$SOURCE" "$TARGET"
        echo "  🔗 Link criado a partir do dotfiles: $TARGET -> $SOURCE"
    else
        echo "  ⏭️  Pasta $folder não encontrada em ~/.config nem em ~/dotfiles. Pulando."
    fi
done

echo ""
echo "Processando arquivos da \$HOME..."

for entry in "${HOME_FILES[@]}"; do
    HOME_NAME="${entry%%:*}"
    REPO_NAME="${entry##*:}"
    TARGET="$HOME/$HOME_NAME"
    SOURCE="$DOTFILES_DIR/$REPO_NAME"

    if [ -L "$TARGET" ]; then
        if [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
            echo "  ✅ $HOME_NAME já é um link para $SOURCE"
        else
            mkdir -p "$BACKUP_DIR"
            mv "$TARGET" "$BACKUP_DIR/${HOME_NAME}.symlink.bak"
            ln -s "$SOURCE" "$TARGET"
            echo "  🔗 Link atualizado: $TARGET -> $SOURCE"
        fi
    elif [ -f "$TARGET" ]; then
        if [ -f "$SOURCE" ]; then
            echo "  🔄 Atualizando $SOURCE com a versão ativa de $TARGET"
            cp -a "$TARGET" "$SOURCE"
            mkdir -p "$BACKUP_DIR"
            mv "$TARGET" "$BACKUP_DIR/$HOME_NAME"
        else
            echo "  📂 Movendo $TARGET para $SOURCE"
            mv "$TARGET" "$SOURCE"
        fi
        ln -s "$SOURCE" "$TARGET"
        echo "  🔗 Link criado: $TARGET -> $SOURCE"
    elif [ -f "$SOURCE" ]; then
        ln -s "$SOURCE" "$TARGET"
        echo "  🔗 Link criado: $TARGET -> $SOURCE"
    fi
done

echo ""
if [ -d "$BACKUP_DIR" ]; then
    echo "🛡️  Backups de segurança salvos em: $BACKUP_DIR"
fi
echo "✅ Concluído! Agora qualquer edição em ~/.config reflete direto em $DOTFILES_DIR."
