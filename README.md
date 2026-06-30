# linux-sc

Coleção de scripts shell para configurar e automatizar tarefas comuns em sistemas Linux, com suporte a múltiplas distribuições (Ubuntu, Debian, Fedora, Arch, openSUSE, Alpine, entre outras).

O projeto conta com um **painel interativo** que centraliza o acesso a todos os scripts: basta escolher uma opção no menu e o script correspondente é baixado e executado automaticamente.

## Como usar

Execute o painel diretamente, sem precisar clonar o repositório:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/MaelllDev/linux-sc/refs/heads/main/painel.sh)
```

Um menu numerado será exibido. Basta digitar o número da opção desejada e pressionar ENTER.

### Executando um script específico

Também é possível baixar e rodar um script individualmente, sem passar pelo painel:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/MaelllDev/linux-sc/refs/heads/main/NOME_DO_SCRIPT.sh)
```

## Requisitos

- Bash
- `curl` ou `wget` instalado
- Permissão de `sudo` (necessária para alguns scripts que instalam pacotes)

## Estrutura do repositório

```
linux-sc/
├── painel.sh          # Menu principal que lista e executa os demais scripts
├── install-fetch.sh   # Um dos scripts disponíveis no painel
└── ...                # Demais scripts do projeto
```

## Adicionando novos scripts

O painel foi feito para ser facilmente expansível. Para adicionar um novo script ao menu, basta:

1. Subir o novo script `.sh` no repositório.
2. Adicionar o nome e a URL "raw" dele nas listas `OPCOES_NOME` e `OPCOES_URL` dentro do `painel.sh`.

## Contribuindo

Sugestões, correções e novos scripts são bem-vindos. Abra uma issue ou envie um pull request.

## Licença

Este projeto está disponível livremente para uso e modificação.
