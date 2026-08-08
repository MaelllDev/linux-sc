# 🐧 linux-sc

> Uma coleção de scripts Shell para automatizar configurações, instalações e tarefas comuns em sistemas Linux.

O **linux-sc** reúne diversos scripts prontos para uso, permitindo configurar servidores e desktops de forma rápida através de um **painel interativo**, compatível com diversas distribuições Linux.

## ✨ Recursos

* 📦 Instalação rápida sem precisar clonar o repositório
* 🖥️ Painel interativo para executar scripts
* ⚡ Download e execução automática dos scripts
* 🔒 Verificação de integridade (SHA-256) antes de executar
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
├── gerar-hashes.sh
├── LICENSE
├── .gitattributes
└── ...
```

**Descrição dos arquivos**

| Arquivo             | Função                                                                |
| ------------------- | --------------------------------------------------------------------- |
| `painel.sh`         | Painel principal responsável por listar e executar os scripts.        |
| `script-exemplo.sh` | Modelo de script para criar novos scripts.                            |
| `gerar-hashes.sh`   | Regenera automaticamente os hashes de integridade do painel.          |
| `LICENSE`           | Licença MIT do projeto.                                               |
| `*.sh`              | Scripts independentes para diferentes tarefas.                        |

---

# 🔒 Verificação de integridade

Antes de executar qualquer script, o painel verifica o **checksum SHA-256** do arquivo baixado contra o hash registrado em `OPCOES_SHA256`:

* Se o hash **confere**, o script é executado normalmente.
* Se o hash **não confere**, o script **não é executado** (pode ter sido alterado ou corrompido no caminho).
* Se não houver hash registrado (ou a ferramenta `sha256sum`/`shasum` não existir), o painel avisa e pergunta se você deseja continuar.

Os hashes são **gerados automaticamente** pelo `gerar-hashes.sh` — você nunca precisa editá-los à mão:

```bash
./gerar-hashes.sh            # regenera os hashes no painel.sh
./gerar-hashes.sh --hook     # instala um pre-commit hook (regeneração automática)
```

O hash é calculado a partir do conteúdo **staged** (`git show :arquivo`), ou seja, exatamente o que será commitado e servido pelo GitHub. Basta dar `git add` no script e o hash gerado corresponderá ao conteúdo publicado.

Com o **pre-commit hook** instalado, basta editar um script, dar `git add` e fazer `git commit`: o hash novo é calculado e incluído no mesmo commit automaticamente.

---

# ➕ Adicionando novos scripts

Adicionar novos scripts ao painel é simples.

1. Adicione o novo arquivo `.sh` ao repositório (use o `script-exemplo.sh` como modelo).
2. Inclua o nome do script na lista `OPCOES_NOME`.
3. Adicione sua URL Raw correspondente em `OPCOES_URL`.
4. Rode `./gerar-hashes.sh` (ou tenha o pre-commit hook instalado com `./gerar-hashes.sh --hook`).
5. Salve as alterações e faça o commit — o hash será gerado automaticamente.

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

Este projeto é distribuído sob a licença **MIT**. Você pode utilizar, modificar e distribuir o código livremente, desde que preserve o aviso de copyright original.

Consulte o arquivo [LICENSE](LICENSE) para os termos completos.

---

<div align="center">

**Desenvolvido por MaelllDev ❤️**

Se este projeto foi útil para você, considere deixar uma ⭐ no repositório.

</div>
