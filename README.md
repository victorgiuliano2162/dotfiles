# Dotfiles

Repositório com minhas configurações pessoais de sistema (Sway/Wayland, terminais, shell e utilitários CLI).

## Estrutura Gerenciada

### `~/.config/`
- **Ambiente Sway / Wayland:** `sway`, `swaync`, `waybar`, `wofi`, `kitty`, `foot`, `kanshi`, `nwg-displays`, `gsimplecal`, `hypr`
- **Editores, Shell e CLI:** `nvim`, `yazi`, `btop`, `bottom`, `micro`, `fish`

### `$HOME`
- `.zshrc` (`zshrc`)
- `.p10k.zsh` (`p10k.zsh`)
- `.gitconfig` (`gitconfig`)

## Como usar

- **No dia a dia:** Como as pastas em `~/.config` e arquivos na `$HOME` são links simbólicos apontando para `~/dotfiles`, basta editar normalmente qualquer arquivo em `~/.config/...` ou `~/.zshrc` e depois comitar as mudanças aqui:
  ```bash
  cd ~/dotfiles
  git add .
  git commit -m "Atualiza configurações"
  git push
  ```
- **Para adicionar uma nova pasta da `~/.config`:** Adicione o nome da pasta no array `CONFIG_FOLDERS` dentro de `./adopt-dotfiles.sh` e `./install.sh`, e execute:
  ```bash
  ./adopt-dotfiles.sh
  ```
- **Em uma nova instalação do sistema:** Clone o repositório em `~/dotfiles` e execute:
  ```bash
  ./install.sh
  ```
