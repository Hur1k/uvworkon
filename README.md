# uvworkon

A tiny helper to quickly activate **global UV-created virtual environments** by name just like conda.

## Prerequisites
- Windows + PowerShell (Other operations: to be continued.)
- UV installed
- A directory to store your global virtual environments

## Setup
1. Choose a folder to keep your global UV virtual environments, e.g. `D:\Dev\uv_venvs`.
2. Create environments in that folder with UV. The simplest way: `uv venv <env_name>`. For advanced options (e.g., specify Python version), refer to the UV documentation.
3. Move these three files into that folder:
   - `uvworkon.ps1`
   - `setup_uvworkon_alias.ps1`
   - `uninstall_uvworkon_alias.ps1`
4. Open PowerShell (pwsh) and run `.\setup_uvworkon_alias.ps1` to write the uvworkon function into your PowerShell profile (#region uvworkon initialize ... #endregion).
5. Restart PowerShell.

## Usage
- List available environments (folders with `Scripts\activate.bat` in the current directory):
```powershell
uvworkon
```
- Activate a specific environment:
```powershell
uvworkon <env_name>
```

## Uninstall
Remove the alias block from your PowerShell profile:
```powershell
.\uninstall_uvworkon_alias.ps1
```

