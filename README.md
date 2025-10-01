# Shikan - Git Workflow Simplificado

**Shikan** é um script interativo para gerenciar workflows Git usando convenções padronizadas (Conventional Commits). Construído com [gum](https://github.com/charmbracelet/gum), oferece uma interface amigável para criar branches, commits, merge requests e releases.

## Índice

- [Características](#-características)
- [Instalação](#-instalação)
- [Uso](#-uso)
- [Comandos Disponíveis](#-comandos-disponíveis)
- [Convenções](#-convenções)
- [Exemplos Práticos](#-exemplos-práticos)

## Características

- **Criação de branches** seguindo padrão `type/name`
- **Commits padronizados** usando Conventional Commits
- **Push automatizado** com verificação de credenciais
- **Merge Requests** via API do GitLab ou navegador
- **Deploy automatizado** com versionamento semântico
- **Configuração de repositório** com Personal Access Token (PAT)
- **Interface interativa** com menus visuais

## Instalação

### Requisitos

- Git
- Bash
- curl
- Linux (testado em Ubuntu/Debian)

### Instalação Rápida

1. **Clone ou baixe o script:**
   ```bash
   chmod +x shikan.sh
   ```

2. **Execute pela primeira vez:**
   ```bash
   ./shikan.sh
   ```

3. **Instale o alias (opcional mas recomendado):**
   - O script perguntará se deseja instalar o alias na primeira execução
   - Isso permite executar `shikan` de qualquer diretório
   - O alias é criado em `~/.local/bin/shikan`

4. **Dependência `gum`:**
   - Instalado automaticamente na primeira execução
   - Requer privilégios sudo

## 🚀 Uso

Execute o script no diretório do seu repositório Git:

```bash
./shikan.sh
# ou, se instalou o alias:
shikan
```

Um menu interativo será apresentado com as seguintes opções:
- `branch` - Criar nova branch
- `commit` - Fazer commit
- `push` - Enviar alterações
- `merge` - Criar Merge Request
- `deploy` - Gerenciar versões e releases
- `add repo` - Configurar repositório remoto
- `help` - Mostrar ajuda
- `sair` - Encerrar

## Comandos Disponíveis

### 1. `branch` - Criar Branch

Cria uma nova branch seguindo o padrão `type/name`.

**Tipos disponíveis:**
- `feat` - Nova funcionalidade
- `fix` - Correção de bug
- `docs` - Documentação
- `style` - Formatação de código
- `refactor` - Refatoração
- `test` - Testes
- `chore` - Manutenção

**Exemplo de uso:**
```bash
shikan
# Selecione: branch
# Escolha o tipo: feat
# Digite o nome: adicionar-login
# Resultado: Branch criada → feat/adicionar-login
```

### 2. `commit` - Fazer Commit

Cria commits seguindo Conventional Commits: `type(scope): description`

**Fluxo:**
1. Seleciona o tipo do commit
2. Opcionalmente adiciona escopo (componente, função, etc.)
3. Seleciona arquivos para adicionar (ou todos)
4. Digita a descrição
5. Opcionalmente faz push

**Exemplo:**
```bash
shikan
# Selecione: commit
# Tipo: feat
# Escopo: auth
# Descrição: adicionar validação de senha
# Resultado: feat(auth): adicionar validação de senha
```

### 3. `push` - Enviar Alterações

Envia a branch atual para o repositório remoto com rastreamento upstream.

**Exemplo:**
```bash
shikan
# Selecione: push
# Resultado: Push realizado para feat/adicionar-login
```

### 4. `merge` - Criar Merge Request

Cria Merge Request no GitLab via API ou navegador.

**Formato do título:** `[TYPE#ID][SCOPE] description`

**Opções:**
- Criação automática via API do GitLab
- Abertura manual no navegador
- Remoção automática da branch após merge

**Exemplo via API:**
```bash
shikan
# Selecione: merge
# Branch de destino: dev
# Criar via API? Sim
# Token: seu-access-token-aqui
# Escopo: autenticação
# Descrição: implementar login com JWT
# Resultado: [FEAT#adicionar-login][autenticação] implementar login com JWT
```

**Exemplo via navegador:**
```bash
shikan
# Selecione: merge
# Branch de destino: main
# Criar via API? Não
# Resultado: Link do MR aberto no navegador
```

### 5. `deploy` - Gerenciar Releases

Automatiza o processo de versionamento e release.

**Suporta:**
- **JavaScript/Node.js** (package.json)
- **Java/Maven** (pom.xml)
- **Python** (pyproject.toml)

**Versionamento Semântico:**
- `major` - Mudanças incompatíveis (1.0.0 → 2.0.0)
- `minor` - Nova funcionalidade compatível (1.0.0 → 1.1.0)
- `patch` - Correção de bugs (1.0.0 → 1.0.1)

**Fluxo:**
1. Seleciona tipo de projeto
2. Define branch de destino (dev, main, prod)
3. Executa comandos de build/teste (opcional)
4. Incrementa versão automaticamente
5. Cria commit de release
6. Faz push
7. Cria tag (opcional)

**Exemplo - Projeto Node.js:**
```bash
shikan
# Selecione: deploy
# Tipo: JS Framework (package.json)
# Branch: main
# Executar build? Sim
# Comandos:
#   npm test
#   npm run build
# Versão atual: 1.2.3
# Incrementar: minor
# Nova versão: 1.3.0
# Resultado: 
#   - package.json atualizado
#   - Commit: release: v1.3.0 - 2025-10-01
#   - Tag: v1.3.0 criada
```

**Exemplo - Projeto Maven:**
```bash
shikan
# Selecione: deploy
# Tipo: Java/Maven (pom.xml)
# Branch: prod
# Executar build? Sim
# Comandos:
#   mvn clean test
#   mvn package
# Versão atual: 2.1.5
# Incrementar: patch
# Nova versão: 2.1.6
```

### 6. `add repo` - Configurar Repositório

Configura o repositório remoto com autenticação via Personal Access Token (PAT).

**Exemplo:**
```bash
shikan
# Selecione: add repo
# Usuário: usuario@example.com.br
# Token: seu-personal-access-token
# Resultado: Repositório configurado para HTTPS com token
```

**Como obter um PAT no GitLab:**
1. Acesse: Settings → Access Tokens
2. Crie um token com permissões: `api`, `read_repository`, `write_repository`
3. Copie e guarde o token (não será mostrado novamente)

## Convenções

### Formato de Branches
```
type/nome-da-branch
```

**Exemplos:**
- `feat/login-social`
- `fix/corrigir-validacao`
- `docs/atualizar-readme`

### Formato de Commits
```
type(scope): description
```

**Exemplos:**
- `feat(auth): adicionar autenticação OAuth`
- `fix: corrigir erro de validação no formulário`
- `docs(readme): atualizar instruções de instalação`
- `refactor(api): simplificar lógica de requisições`

### Formato de Merge Requests
```
[TYPE#ID][SCOPE] description
```

**Exemplos:**
- `[FEAT#login-social][autenticação] implementar login com Google e Facebook`
- `[FIX#validacao][formulários] corrigir validação de email`
- `[DOCS#readme][documentação] adicionar exemplos de uso`

## Exemplos Práticos

### Exemplo 1: Nova Funcionalidade Completa

```bash
# 1. Criar branch para nova funcionalidade
shikan
> branch
> feat
> sistema-notificacoes
# Branch criada: feat/sistema-notificacoes

# 2. Fazer alterações no código...

# 3. Commit das alterações
shikan
> commit
> feat
> notifications
> adicionar sistema de notificações em tempo real
> Adicionar todos os arquivos? Sim
> Fazer push? Sim
# Commit: feat(notifications): adicionar sistema de notificações em tempo real

# 4. Criar Merge Request
shikan
> merge
> dev
> Criar via API? Sim
> Token: [seu-token]
> Escopo: notificações
> Descrição: implementar websockets para notificações
# MR criado: [FEAT#sistema-notificacoes][notificações] implementar websockets para notificações
```

### Exemplo 2: Correção de Bug

```bash
# 1. Criar branch para correção
shikan
> branch
> fix
> corrigir-timeout
# Branch criada: fix/corrigir-timeout

# 2. Corrigir o bug...

# 3. Commit seletivo
shikan
> commit
> fix
> api
> aumentar timeout de requisições para 30s
> Adicionar todos? Não
> Selecionar: [ESPAÇO] src/api/config.js
> Fazer push? Sim

# 4. Criar MR
shikan
> merge
> main
> Criar via API? Não
# Link aberto no navegador
```

### Exemplo 3: Release de Produção

```bash
# 1. Preparar release
shikan
> deploy
> JS Framework (package.json)
> main
> Executar comandos? Sim
> Comandos:
  npm run lint
  npm test
  npm run build
> Versão atual: 2.3.1
> Incrementar: minor
# Nova versão: 2.4.0
> Criar commit? Sim
> Fazer push? Sim
> Criar tag? Sim
> Fazer push da tag? Sim
# Release v2.4.0 criada e enviada!
```

### Exemplo 4: Atualização de Documentação

```bash
# 1. Criar branch
shikan
> branch
> docs
> atualizar-api-docs

# 2. Atualizar documentação...

# 3. Commit
shikan
> commit
> docs
> api
> atualizar documentação dos endpoints REST
> Fazer push? Sim

# 4. Merge direto
shikan
> merge
> dev
```

## Tratamento de Erros

O script inclui verificações para:
- ✔ Repositório Git válido
- ✔ Commits existentes antes de criar branches
- ✔ Branch não existe no remoto antes de MR
- ✔ Arquivos alterados antes de commit
- ✔ Credenciais válidas para push/API
- ✔ Arquivos de configuração do projeto (package.json, pom.xml, etc.)

## Contribuindo

Sugestões e melhorias são bem-vindas! Sinta-se à vontade para:
- Reportar bugs
- Sugerir novas funcionalidades
- Melhorar a documentação

## Licença

Livre para uso e modificação.

## Agradecimentos

Criado usando [gum](https://github.com/charmbracelet/gum) - uma ferramenta incrível para criar scripts shell interativos.

---

**Dica:** Pressione `ESC` a qualquer momento para cancelar uma operação!
