# 🐧 linux-sc

> Uma coleção de scripts Shell para automatizar configurações, instalações e tarefas comuns em sistemas Linux.

O **linux-sc** reúne diversos scripts prontos para uso, permitindo configurar servidores e desktops de forma rápida através de um **painel interativo**, compatível com diversas distribuições Linux.

## ✨ Recursos

* 📦 Instalação rápida sem precisar clonar o repositório
* 🖥️ Painel interativo para executar scripts
* ⚡ Download e execução automática dos scripts
* 🐧 Compatível com diversas distribuições Linux
* 🔧 Fácil de expandir com novos scripts
* 📂 Organização simples e modular

## 📌 Distribuições suportadas

Entre as distribuições compatíveis estão:

* Ubuntu
* Debian
* Fedora
* Arch Linux
* openSUSE
* Alpine Linux
* e outras distribuições baseadas em Bash.

---

# 🚀 Execução rápida

Você pode executar o painel diretamente pelo terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/MaelllDev/linux-sc/refs/heads/main/painel.sh)
```

Após executar o comando, será exibido um menu numerado contendo todos os scripts disponíveis.

Basta escolher uma opção e pressionar **ENTER**.

---

# 📥 Executando apenas um script

Caso queira utilizar somente um script específico:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/MaelllDev/linux-sc/refs/heads/main/NOME_DO_SCRIPT.sh)
```

Substitua `NOME_DO_SCRIPT.sh` pelo arquivo desejado.

---

# 📋 Requisitos

Antes de executar os scripts, certifique-se de possuir:

* Bash
* `curl` ou `wget`
* Permissão de `sudo` (quando necessária)

---

# 📁 Estrutura do projeto

```text
linux-sc/
├── painel.sh
├── install-fetch.sh
├── script-exemplo.sh
└── ...
```

**Descrição dos arquivos**

| Arquivo     | Função                                                         |
| ----------- | -------------------------------------------------------------- |
| `painel.sh` | Painel principal responsável por listar e executar os scripts. |
| `*.sh`      | Scripts independentes para diferentes tarefas.                 |

---

# ➕ Adicionando novos scripts

Adicionar novos scripts ao painel é simples.

1. Adicione o novo arquivo `.sh` ao repositório.
2. Inclua o nome do script na lista `OPCOES_NOME`.
3. Adicione sua URL Raw correspondente em `OPCOES_URL`.
4. Salve as alterações no `painel.sh`.

O novo script aparecerá automaticamente no menu.

---

# 🤝 Contribuindo

Contribuições são sempre bem-vindas.

Você pode colaborar através de:

* Correção de bugs
* Novos scripts
* Melhorias de documentação
* Otimizações de código
* Sugestões de funcionalidades

Basta abrir uma *Issue* ou enviar um *Pull Request*.

---

# 📄 Licença

Este projeto é de código aberto e pode ser utilizado, modificado e distribuído livremente conforme os termos da licença adotada pelo repositório.

---

<div align="center">

**Desenvolvido por MaelllDev ❤️**

Se este projeto foi útil para você, considere deixar uma ⭐ no repositório.

</div>
