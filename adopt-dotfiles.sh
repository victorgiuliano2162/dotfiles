#!/usr/bin/env bash
set -e

echo "📦 Adotando configurações para o diretório dotfiles..."

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

# Lista de pastas que você quer gerenciar
CONFIG_FOLDERS=("sway" "waybar" "kitty" "gtk-3.0" "wofi")

# Cria o diretório dotfiles se não existir
mkdir -p "$DOTFILES_DIR"

for folder in "${CONFIG_FOLDERS[@]}"; do
    TARGET="$CONFIG_DIR/$folder"
    SOURCE="$DOTFILES_DIR/$folder"

    echo "Processando: $folder"

    # Caso 1: ~/.config/pasta é um link simbólico
    if [ -L "$TARGET" ]; then
        # Verifica se aponta para o lugar certo
        if [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
            echo "  ✅ Link já existe e aponta para o local correto."
        else
            echo "  ⚠️  Link existente aponta para outro lugar. Recriando..."
            rm "$TARGET"
            ln -sf "$SOURCE" "$TARGET"
            echo "  ✅ Link recriado."
        fi
        continue
    fi

    # Caso 2: ~/.config/pasta é um diretório comum (ou arquivo)
    if [ -e "$TARGET" ]; then
        # Se for um diretório comum, precisamos mover para o dotfiles
        if [ -d "$TARGET" ]; then
            if [ -d "$SOURCE" ]; then
                # A origem já existe em dotfiles → fazemos backup do destino e linkamos
                echo "  ⚠️  $SOURCE já existe. Fazendo backup de $TARGET para $TARGET.bak"
                mv "$TARGET" "$TARGET.bak"
            else
                # Move a pasta inteira para dotfiles
                echo "  📂 Movendo $TARGET para $SOURCE"
                mv "$TARGET" "$SOURCE"
            fi
        else
            # É um arquivo (não esperado, mas tratamos)
            echo "  ⚠️  $TARGET é um arquivo, não um diretório. Movendo como arquivo."
            mv "$TARGET" "$SOURCE"
        fi
    fi

    # Agora, se a origem existe em dotfiles, cria o link
    if [ -d "$SOURCE" ] || [ -f "$SOURCE" ]; then
        ln -sf "$SOURCE" "$TARGET"
        echo "  🔗 Link criado: $TARGET -> $SOURCE"
    else
        echo "  ❌ ERRO: $SOURCE não foi criado. Pulei essa pasta."
    fi
done

# Tratamento especial para .zshrc (se quiser)
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    if [ -f "$DOTFILES_DIR/zshrc" ]; then
        echo "  ⚠️  $DOTFILES_DIR/zshrc já existe. Fazendo backup de ~/.zshrc"
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    else
        echo "📂 Movendo ~/.zshrc para $DOTFILES_DIR/zshrc"
        mv "$HOME/.zshrc" "$DOTFILES_DIR/zshrc"
    fi
    ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
    echo "🔗 Link criado para .zshrc"
elif [ -L "$HOME/.zshrc" ]; then
    echo "✅ .zshrc já é um link."
fi

echo "✅ Concluído! Agora você pode commitar as mudanças no Git:"
echo "   cd $DOTFILES_DIR && git add . && git commit -m 'Adotando configurações'"