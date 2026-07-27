#!/usr/bin/env bash

# Encerrar se algum comando falhar
set -e

echo "🚀 Iniciando a vinculação dos Dotfiles..."

# Garante que o diretório ~/.config existe
mkdir -p ~/.config

# Diretório base onde o repositório foi clonado
DOTFILES_DIR="$HOME/dotfiles"

# Lista de pastas de configuração para vincular
CONFIG_FOLDERS=("sway" "waybar" "foot" "gtk-3.0")

for folder in "${CONFIG_FOLDERS[@]}"; do
    TARGET="$HOME/.config/$folder"
    SOURCE="$DOTFILES_DIR/$folder"

    # Se a pasta de origem existir dentro do repositório
    if [ -d "$SOURCE" ]; then
        # Se já existir uma pasta normal na ~/.config, faz backup por segurança
        if [ -d "$TARGET" ] && [ ! -L "$TARGET" ]; then
            echo "📦 Fazendo backup de $TARGET para $TARGET.bak"
            mv "$TARGET" "$TARGET.bak"
        fi

        echo "🔗 Criando link simbólico para: $folder"
        ln -sf "$SOURCE" "$TARGET"
    else
        echo "⚠️  Aviso: Pasta $SOURCE não encontrada no repositório."
    fi
done

echo "✅ Todos os dotfiles foram vinculados com sucesso!"

