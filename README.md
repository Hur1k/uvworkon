# uvworkon

A tiny helper to quickly activate **global UV-created virtual environments** by name just like workon.

## Prerequisites
- UV installed
- A directory to store your global virtual environments
- One of:
  - Windows + PowerShell
  - Linux + `bash` or `zsh`

## Setup
1. Choose a folder to keep your global UV virtual environments, e.g.:
   - Windows: `D:\Dev\uv_venvs`
   - Linux: `/opt/dev/uv_venvs` or `~/dev/uv_venvs`
2. Create environments in that folder with UV. The simplest way:
```bash
uv venv <env_name>
```
3. Move the matching files into that folder.

### Windows (PowerShell)
Required files:
- `uvworkon.ps1`
- `setup_uvworkon_alias.ps1`
- `uninstall_uvworkon_alias.ps1`

Run:
```powershell
.\setup_uvworkon_alias.ps1
```

This writes the `uvworkon` function into your PowerShell profile. Restart PowerShell or run:
```powershell
. $PROFILE
```

### Linux (`bash` / `zsh`)
Required files:
- `uvworkon.sh`
- `setup_uvworkon_alias.sh`
- `uninstall_uvworkon_alias.sh`

Quick install with one command:
```bash
curl -fsSL https://raw.githubusercontent.com/Hur1k/uvworkon/main/install.sh | bash
```

If GitHub raw access is slow or blocked:
```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/Hur1k/uvworkon/main/install.sh | bash
```

By default this installs the scripts into `~/.local/uv_venvs`, and that directory also becomes `UVWORKON_HOME`.
Create or move your UV environments under that directory, or override it when installing:
```bash
curl -fsSL https://raw.githubusercontent.com/Hur1k/uvworkon/main/install.sh | env UVWORKON_INSTALL_DIR="$HOME/dev/uv_venvs" bash
```

You can still forward setup options:
```bash
curl -fsSL https://raw.githubusercontent.com/Hur1k/uvworkon/main/install.sh | bash -s -- --shell zsh
```

Run:
```bash
./setup_uvworkon_alias.sh
```

If `uv` is not already available in `PATH`, the setup script will prompt whether to install it via the latest `uv-custom` Gitee release before continuing.

For non-interactive installs, use `install.sh` or pass `--install-uv` explicitly. `install.sh` defaults to automatic `uv` installation when `uv` is missing.

By default, the installer writes to:
- `~/.bashrc` when the current shell is `bash`
- `~/.zshrc` when the current shell is `zsh`
- `~/.profile` as a fallback

You can also target a specific rc file:
```bash
./setup_uvworkon_alias.sh --shell zsh
./setup_uvworkon_alias.sh --rc-file ~/.bashrc
```

Then reload your shell:
```bash
source ~/.bashrc
```
or:
```bash
source ~/.zshrc
```

## Usage
- List available environments:
  - Windows looks for `Scripts\activate.bat`
  - Linux looks for `bin/activate`
```text
uvworkon
```
- Activate a specific environment:
```text
uvworkon <env_name>
```

## Uninstall
### Windows
```powershell
.\uninstall_uvworkon_alias.ps1
```

### Linux
```bash
./uninstall_uvworkon_alias.sh
```
