# Linux Scripts

🐧 Coleção de scripts Bash para automatizar tarefas chatas em Linux. Porque ninguém quer ficar repetindo comandos na mão.

## 📋 Scripts Disponíveis

### `install-fetch.sh` - Instalação automática de Fetch
Instala automaticamente **neofetch** ou **fastfetch** em praticamente qualquer distro Linux e configura para rodar toda vez que você abre um terminal.

**Distros suportadas:**
- Ubuntu / Debian
- Fedora / RHEL / CentOS
- Arch Linux
- openSUSE
- Alpine Linux
- E muitas outras...

**O que faz:**
- Detecta automaticamente qual gerenciador de pacotes usar
- Tenta instalar neofetch primeiro (se disponível)
- Se não conseguir, faz fallback pro fastfetch
- Se o pacote não está nos repos, baixa o binário direto do GitHub
- Configura `.bashrc` e `.zshrc` pra rodar o fetch automaticamente
- Suporta arquiteturas x86_64 e ARM64

**Uso:**
```bash
chmod +x install-fetch.sh
./install-fetch.sh
sudo ./install-fetch.sh  # se precisar instalar pacotes
