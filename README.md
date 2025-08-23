<p align="center">
  <img alt="Neovim" src="https://raw.githubusercontent.com/neovim/neovim.github.io/master/logos/neovim-logo-300x87.png" height="80" />
  <p align="center">Nviq</p>
</p>

---

# Installation

- Requirements
  - [Neovim](https://github.com/neovim/neovim) 0.11 or later
  - [Git](https://github.com/git/git)
  - [tree-sitter](https://github.com/tree-sitter/tree-sitter) CLI (0.25.0 or later)
  - [ripgrep](https://github.com/BurntSushi/ripgrep) (optional)
  - [fd](https://github.com/sharkdp/fd) (optional)

- Clone the repository
  - Windows
    ``` ps1
    git clone --depth=1 https://github.com/AnthonyK213/nviq.git "$env:LOCALAPPDATA\nvim"
    ```
  - GNU/Linux
    ``` sh
    git clone --depth=1 https://github.com/AnthonyK213/nviq.git "${XDG_DATA_HOME:-$HOME/.config}"/nvim
    ```

# Documentation

[documentation](./doc/nviq.txt)
