#!/bin/bash
set -euo pipefail  # Adicionado -u para variáveis não definidas e -o pipefail

# Criado usando gum - https://github.com/charmbracelet/gum

# Para dar permissão de execução
# chmod +x shikan.sh

# Formato das branchs:
# type/ID-or-name

# Formato dos commits (escopo aqui deve ser algo curto, como o nome de uma função ou componente):
# type(scope): description

# Formato dos Merge Resquests (escopo aqui deve ser do contexto da alteração, como nome do fluxo ou módulo):
# [TYPE#ID][SCOPE] description

GUM=$(command -v gum || true)

### Funções auxiliares

install_gum() {
    echo "📦 gum não encontrado, instalando..."

    if ! command -v curl > /dev/null; then
        echo "✘ curl não encontrado. Instale curl primeiro."
        exit 1
    fi

    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) echo "Arquitetura não suportada: $ARCH"; exit 1 ;;
    esac

    VERSION=$(curl -s https://api.github.com/repos/charmbracelet/gum/releases/latest \
        | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

    if [[ -z "$VERSION" ]]; then
        echo "✘ Erro ao obter versão do gum"
        exit 1
    fi

    DEB_URL="https://github.com/charmbracelet/gum/releases/download/v${VERSION}/gum_${VERSION}_${ARCH}.deb"
    TMP_DEB="/tmp/gum_${VERSION}_${ARCH}.deb"

    echo "Baixando $DEB_URL..."
    if ! curl -L -o "$TMP_DEB" "$DEB_URL"; then
        echo "✘ Erro ao baixar gum"
        exit 1
    fi

    if ! sudo dpkg -i "$TMP_DEB"; then
        sudo apt-get install -f -y
    fi

    rm -f "$TMP_DEB"
    echo "✔ gum instalado!"
}

set_alias() {
    CMD_NAME="shikan"
    local target="$HOME/.local/bin/$CMD_NAME"
    mkdir -p "$HOME/.local/bin"

    ln -sf "$(realpath "$0")" "$target"

    $GUM style --foreground 46 "✔ Alias instalado: agora você pode rodar '$CMD_NAME' de qualquer lugar." >&2

    exit 0
}

validate_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        $GUM style --foreground 196 "✘ Erro: Este diretório não é um repositório git." >&2
        exit 1
    fi
}

choose_type() {
    local context="$1"
    $GUM choose "feat" "fix" "docs" "style" "refactor" "test" "chore" "voltar" --header "Selecione o tipo de $context (Conventional Commits):"
}

get_scope() {
    $GUM input --placeholder "Digite o escopo (função, componente, etc.) - opcional"
}

get_description() {
    $GUM input --placeholder "Digite a descrição do commit"
}

choose_project_type() {
    $GUM choose "JS Framework (package.json)" "Java/Maven (pom.xml)" "Python (pyproject.toml)" "Manual" "voltar" --header "Selecione o tipo de projeto:"
}

choose_version_bump() {
    $GUM choose "major" "minor" "patch" --header "Qual parte da versão deseja incrementar?"
}

get_target_branch() {
    $GUM input --placeholder "Digite a branch de destino da nova versão (ex: dev, main, prod)"
}

get_manual_version() {
    $GUM input --placeholder "Digite a nova versão (ex: 1.2.3)"
}

bump_version() {
    local current="$1"
    local part="$2"
    
    IFS='.' read -r major minor patch <<< "$current"

    case $part in
        major) ((major++)); minor=0; patch=0 ;;
        minor) ((minor++)); patch=0 ;;
        patch) ((patch++)) ;;
    esac

    echo "${major}.${minor}.${patch}"
}

deploy_js() {
    if [[ ! -f "package.json" ]]; then
        $GUM style --foreground 196 "✘ package.json não encontrado" >&2
        return 1
    fi

    local current new_version part
    current=$(jq -r '.version' package.json 2>/dev/null || echo "0.1.0")
    
    $GUM style --foreground 212 "Versão atual: $current" >&2
    
    part=$(choose_version_bump)
    new_version=$(bump_version "$current" "$part")

    jq --arg v "$new_version" '.version = $v' package.json > package.tmp && mv package.tmp package.json

    $GUM style --foreground 46 "✔ Versão atualizada no package.json: $current → $new_version" >&2
    echo "$new_version"
}

deploy_maven() {
    if [[ ! -f "pom.xml" ]]; then
        $GUM style --foreground 196 "✘ pom.xml não encontrado" >&2
        return 1
    fi

    local current new_version part
    current=$(xmllint --xpath "string(//project/version)" pom.xml 2>/dev/null || echo "0.1.0")
    
    $GUM style --foreground 212 "Versão atual: $current" >&2
    
    part=$(choose_version_bump)
    new_version=$(bump_version "$current" "$part")

    cp pom.xml pom.xml.bak

    sed -i "0,/<version>.*<\/version>/s/<version>.*<\/version>/<version>$new_version<\/version>/" pom.xml

    $GUM style --foreground 46 "✔ Versão atualizada no pom.xml: $current → $new_version" >&2
    echo "$new_version"
}

deploy_python() {
    if [[ ! -f "pyproject.toml" ]]; then
        $GUM style --foreground 196 "✘ pyproject.toml não encontrado" >&2
        return 1
    fi

    local current new_version part
    current=$(grep -E '^version\s*=' pyproject.toml | sed -E 's/.*=\s*"([^"]+)".*/\1/' 2>/dev/null || echo "0.1.0")
    
    $GUM style --foreground 212 "Versão atual: $current" >&2
    
    part=$(choose_version_bump)
    new_version=$(bump_version "$current" "$part")

    cp pyproject.toml pyproject.toml.bak

    sed -i "s/^version\s*=\s*\".*\"/version = \"$new_version\"/" pyproject.toml

    $GUM style --foreground 46 "✔ Versão atualizada no pyproject.toml: $current → $new_version" >&2
    echo "$new_version"
}

run_pre_deploy_commands() {
    if $GUM confirm "Deseja executar comandos de build/teste antes do deploy?"; then
        local commands
        commands=$($GUM write --placeholder "Digite os comandos a executar (um por linha):" --height 5)
        
        if [[ -n "$commands" ]]; then
            $GUM style --foreground 27 "Executando comandos de pré-deploy..." >&2
            
            while IFS= read -r command; do
                if [[ -n "$command" ]]; then
                    $GUM style --foreground 27 "Executando: $command" >&2
                    if ! eval "$command"; then
                        $GUM style --foreground 196 "✘ Erro ao executar: $command" >&2
                        return 1
                    fi
                fi
            done <<< "$commands"
            
            $GUM style --foreground 46 "✔ Comandos de pré-deploy executados com sucesso!" >&2
        fi
    fi
    return 0
}

get_target_branch() {
    $GUM input --placeholder "Digite a branch de destino (ex: develop ou main)"
}

get_pat_token() {
    $GUM input --placeholder "Digite seu Personal Access Token (PAT)" --password
}

get_mr_title() {
    local branch_name current_type current_id current_scope mr_title
    branch_name=$(git rev-parse --abbrev-ref HEAD)
    
    # Extrair tipo e ID da branch (formato: type/id-or-name)
    if [[ "$branch_name" =~ ^([^/]+)/(.+)$ ]]; then
        current_type="${BASH_REMATCH[1]^^}"  # Converter para maiúscula
        current_id="${BASH_REMATCH[2]}"
    else
        current_type=""
        current_id=""
    fi
    
    current_scope=$($GUM input --placeholder "Digite o escopo do MR (contexto da alteração, módulo, fluxo, etc.)")
    
    local description
    description=$($GUM input --placeholder "Digite a descrição do MR")
    
    # Montar título no formato [TYPE#ID][SCOPE] description
    if [[ -n "$current_type" && -n "$current_id" && -n "$current_scope" && -n "$description" ]]; then
        mr_title="[${current_type}#${current_id}][${current_scope}] ${description}"
    elif [[ -n "$current_type" && -n "$current_id" && -n "$description" ]]; then
        mr_title="[${current_type}#${current_id}] ${description}"
    else
        mr_title=$($GUM input --placeholder "Título do Merge Request (formato: [TYPE#ID][SCOPE] description)")
    fi
    
    echo "$mr_title"
}

get_mr_description() {
    $GUM write --placeholder "Descrição do Merge Request (opcional)" --height 5
}

###### Funções de configuração do repositório

add_remote() {
    validate_git_repo

    local user token user_encoded current_url clean_url remote_url
    user=$($GUM input --placeholder "Digite seu usuário GitLab (ex: usuario@example.com.br)")
    [[ -z "$user" ]] && { $GUM style --foreground 196 "✘ Usuário é obrigatório." >&2; return; }

    token=$($GUM input --placeholder "Digite seu Personal Access Token (PAT)" --password)
    [[ -z "$token" ]] && { $GUM style --foreground 196 "✘ Token é obrigatório." >&2; return; }

    user_encoded=${user//@/%40}

    current_url=$(git remote get-url origin)
    clean_url=$(echo "$current_url" | sed -E 's#https://[^/]+@#https://#' | sed 's/\.git$//')

    remote_url="https://${user_encoded}:${token}@${clean_url#https://}.git"

    git remote set-url origin "$remote_url"

    $GUM style --foreground 46 "✔ Repositório configurado para HTTPS com token" >&2
}

###### Funções de gerenciamento de branch

branch() {
    if ! git rev-parse HEAD >/dev/null 2>&1; then
        $GUM style --foreground 226 "⚠ Nenhum commit encontrado no repositório." >&2
        
        if $GUM confirm "Deseja fazer o commit inicial do shikan.sh?"; then
            commit
            $GUM style --foreground 46 "✔ Commit inicial realizado com shikan.sh" >&2
        else
            $GUM style --foreground 196 "✘ É necessário ter ao menos um commit no repositório para criar branches." >&2
            return
        fi
    fi

    local base_branch
    base_branch=$(git rev-parse --abbrev-ref HEAD)

    local prefix_choice branch_type code branch_name
    prefix_choice=$(choose_type "branch")

    if [[ "$prefix_choice" == "voltar" ]]; then
        return
    fi

    branch_type="$prefix_choice"
    [[ "$branch_type" == "" ]] && return

    branch_name=$($GUM input --placeholder "Digite o nome da branch (use nomes curtos):")

    if [[ -z "$branch_name" ]]; then
        $GUM style --foreground 196 "✘ Nome da branch não pode estar vazio." >&2
        return
    fi

    branch_name=$(echo "$branch_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    branch_name="${branch_type}/${branch_name}"

    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        $GUM style --foreground 196 "✘ Branch $branch_name já existe." >&2
        return
    fi

    git checkout -b "$branch_name"
    $GUM style --foreground 46 "✔ Branch $branch_name criada a partir da branch $base_branch" >&2
}

###### Funções de commit

commit() {
    validate_git_repo
    
    local has_modified has_staged has_untracked
    has_modified=$(git diff-index --quiet HEAD -- 2>/dev/null; echo $?)
    has_staged=$(git diff --staged --quiet 2>/dev/null; echo $?)
    has_untracked=$(git ls-files --others --exclude-standard | wc -l)

    if [[ $has_modified -eq 0 && $has_staged -eq 0 && $has_untracked -eq 0 ]]; then
        $GUM style --foreground 196 "✘ Nenhuma mudança para commit." >&2
        return
    fi

    local staged_files
    staged_files=$(git diff --staged --name-only)
    
    if [[ -n "$staged_files" ]]; then
        $GUM style --foreground 33 "⚠ Há arquivos já no staging area:" >&2
        echo "$staged_files" | while read -r file; do
            $GUM style --foreground 33 "  • $file" >&2
        done
        
        if $GUM confirm "Deseja remover estes arquivos do staging e selecionar manualmente?"; then
            git reset HEAD .
            $GUM style --foreground 46 "✔ Staging area limpo!" >&2
        fi
    fi

    local commit_type
    commit_type=$(choose_type "commit")
    
    if [[ "$commit_type" == "voltar" ]]; then
        return
    fi

    if $GUM confirm "Deseja adicionar todos os arquivos?"; then
        git add .
    else
        local files selected
        files=$(git status --porcelain | awk '{print $2}')

        if [[ -z "$files" ]]; then
            $GUM style --foreground 196 "✘ Nenhum arquivo alterado para adicionar." >&2
            return
        fi

        selected=$($GUM choose --no-limit --header "Selecione os arquivos para adicionar (Aperte ESPAÇO para selecionar):" $files)

        if [[ -n "$selected" ]]; then
            echo "$selected" | xargs git add
        else
            $GUM style --foreground 196 "✘ Nenhum arquivo selecionado." >&2
            return
        fi
    fi

    local scope
    scope=$(get_scope)

    local description
    description=$(get_description)

    if [[ -z "$description" ]]; then
        $GUM style --foreground 196 "✘ Descrição do commit não pode estar vazia." >&2
        return
    fi

    local commit_msg
    if [[ -n "$scope" ]]; then
        commit_msg="${commit_type}(${scope}): ${description}"
    else
        commit_msg="${commit_type}: ${description}"
    fi

    git commit -m "$commit_msg"
    $GUM style --foreground 46 "✔ Commit realizado: $commit_msg" >&2

    if $GUM confirm "Deseja fazer push das alterações?"; then
        local branch_name
        branch_name=$(git rev-parse --abbrev-ref HEAD)
        
        if git push -u origin "$branch_name" 2>&1; then
            $GUM style --foreground 46 "✔ Push realizado com sucesso!" >&2
        else
            $GUM style --foreground 196 "✘ Erro ao fazer push. Verifique suas credenciais." >&2
        fi
    fi
}

###### Funções de push

push() {
    validate_git_repo

    local branch_name
    branch_name=$(git rev-parse --abbrev-ref HEAD)

    if ! $GUM spin --spinner "points" --title "Fazendo push das alterações..." -- git push -u origin "$branch_name"; then
        $GUM style --foreground 196 "✘ Erro ao fazer push" >&2
        return
    fi

    $GUM style --foreground 46 "✔ Push realizado para $branch_name" >&2
}

###### Funções de merge request

merge() {
    validate_git_repo

    local target token url branch_name host project_path project_id api_url title description response web_url
    
    branch_name=$(git rev-parse --abbrev-ref HEAD)
    
    if [[ "$branch_name" == "main" || "$branch_name" == "master" || "$branch_name" == "dev" || "$branch_name" == "desenv" || "$branch_name" == "melhorias" ]]; then
        $GUM style --foreground 196 "✘ Você não pode criar um MR a partir da branch $branch_name." >&2
        return
    fi
    
    if ! git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
        $GUM style --foreground 196 "✘ A branch $branch_name ainda não foi enviada ao repositório remoto. Execute 'push' primeiro." >&2
        return
    fi

    target=$(get_target_branch)
    [[ -z "$target" ]] && { $GUM style --foreground 196 "✘ Branch de destino é obrigatória." >&2; return; }

    url=$(git remote get-url origin | sed 's/\.git$//')

    if [[ "$url" =~ ^git@ ]]; then
        url=$(echo "$url" | sed -E 's#git@(.*):(.*)#https://\1/\2#')
    fi

    if $GUM confirm "Deseja criar o MR automaticamente via API? (senão, será aberto o link no navegador)"; then
        token=$(get_pat_token)
        [[ -z "$token" ]] && { $GUM style --foreground 196 "✘ Token é obrigatório para criação via API." >&2; return; }

        title=$(get_mr_title)
        [[ -z "$title" ]] && { $GUM style --foreground 196 "✘ Título do MR é obrigatório." >&2; return; }

        description=$(get_mr_description)

        host=$(echo "$url" | sed -E 's#https://([^/]+)/.*#\1#')
        project_path=$(echo "$url" | sed -E 's#https://[^/]+/(.*)#\1#')
        project_id=$(echo "$project_path" | sed 's#/#%2F#g')

        api_url="https://${host}/api/v4/projects/${project_id}/merge_requests"

        local payload
        if [[ -n "$description" ]]; then
            payload="{
                \"source_branch\": \"${branch_name}\",
                \"target_branch\": \"${target}\",
                \"title\": \"${title}\",
                \"description\": \"${description}\",
                \"remove_source_branch\": true
            }"
        else
            payload="{
                \"source_branch\": \"${branch_name}\",
                \"target_branch\": \"${target}\",
                \"title\": \"${title}\",
                \"remove_source_branch\": true
            }"
        fi

        response=$(curl -s --request POST \
          --header "PRIVATE-TOKEN: $token" \
          --header "Content-Type: application/json" \
          --data "$payload" \
          "$api_url")

        if ! command -v jq > /dev/null; then
            $GUM style --foreground 196 "✘ jq não encontrado. Instale jq para processar a resposta da API." >&2
            echo "Resposta da API: $response"
            return
        fi

        web_url=$(echo "$response" | jq -r '.web_url // empty')

        if [[ -n "$web_url" ]]; then
            $GUM style --foreground 46 "✔ Merge Request criado com sucesso!" >&2
            echo "🔗 URL: $web_url"
            
            if $GUM confirm "Deseja abrir o MR no navegador?"; then
                xdg-open "$web_url" 2>/dev/null || open "$web_url" 2>/dev/null || echo "Abra manualmente: $web_url"
            fi
        else
            $GUM style --foreground 196 "✘ Falha ao criar Merge Request" >&2
            echo "Erro: $(echo "$response" | jq -r '.message // .error // .')"
        fi
    else
        local mr_url="${url}/-/merge_requests/new?merge_request[source_branch]=${branch_name}&merge_request[target_branch]=${target}"
        
        $GUM style --foreground 27 "🌐 Abra seu merge request em:" >&2
        echo "$mr_url"
        
        if $GUM confirm "Deseja abrir o link no navegador?"; then
            xdg-open "$mr_url" 2>/dev/null || open "$mr_url" 2>/dev/null || echo "Abra manualmente: $mr_url"
        fi
    fi
}

###### Funções de deploy

deploy() {
    validate_git_repo

    local project_type target new_version
    
    project_type=$(choose_project_type)
    [[ "$project_type" == "voltar" ]] && return

    target=$(get_target_branch)
    [[ -z "$target" ]] && { $GUM style --foreground 196 "✘ Branch de destino é obrigatória." >&2; return; }

    if ! $GUM spin --spinner "points" --title "Preparando branch para release..." -- bash -c "
        git checkout '$target' &&
        git pull origin '$target' &&
        git fetch --prune
    "; then
        $GUM style --foreground 196 "✘ Erro ao preparar branch para release" >&2
        return 1
    fi

    if ! run_pre_deploy_commands; then
        return 1
    fi

        case $project_type in
        "JS Framework (package.json)")
            new_version=$(deploy_js) ;;
        "Java/Maven (pom.xml)")
            new_version=$(deploy_maven) ;;
        "Python (pyproject.toml)")
            new_version=$(deploy_python) ;;
        *)
            $GUM style --foreground 196 "✘ Tipo de projeto inválido." >&2
            return 1 ;;
    esac

    if [[ -z "$new_version" ]]; then
        $GUM style --foreground 196 "✘ Erro ao obter nova versão." >&2
        return 1
    fi

    git add $(ls package.json pom.xml pyproject.toml 2>/dev/null | head -10) || true

    if $GUM confirm "Deseja criar o commit de release v$new_version?"; then
        local commit_msg="release: v$new_version - $(date +%Y-%m-%d)"
        
        if git commit -m "$commit_msg"; then
            $GUM style --foreground 46 "✔ Commit de release criado: $commit_msg" >&2
            
            if $GUM confirm "Deseja fazer push da release para $target?"; then
                if $GUM spin --spinner "points" --title "Enviando release para o repositório remoto..." -- git push origin "$target"; then
                    $GUM style --foreground 46 "✔ Release v$new_version enviada para $target" >&2
                else
                    $GUM style --foreground 196 "✘ Erro ao fazer push da release" >&2
                    return 1
                fi
            fi

            if $GUM confirm "Deseja criar uma tag para esta release?"; then
                if git tag -a "$new_version" -m "Release v$new_version"; then
                    $GUM style --foreground 46 "✔ Tag v$new_version criada" >&2
                    
                    if $GUM confirm "Deseja fazer push da tag?"; then
                        if git push origin "$new_version"; then
                            $GUM style --foreground 46 "✔ Tag v$new_version enviada para o repositório" >&2
                        else
                            $GUM style --foreground 196 "✘ Erro ao fazer push da tag" >&2
                        fi
                    fi
                else
                    $GUM style --foreground 196 "✘ Erro ao criar tag" >&2
                fi
            fi
        else
            $GUM style --foreground 196 "✘ Erro ao criar commit de release" >&2
            return 1
        fi
    else
        $GUM style --foreground 196 "Release cancelada pelo usuário." >&2
        return 1
    fi
}

###### Funções de ajuda

help() {
    echo ""
    echo "Comandos disponíveis (Pressione ESC para sair a qualquer momento):"
    echo "  branch        - Criar nova branch usando convensão de commits"
    echo "  commit        - Fazer commit com mensagem padronizada"
    echo "  push          - Enviar branch atual para o remoto"
    echo "  merge         - Abrir merge request no repositório remoto"
    echo "  deploy        - Atualizar versão do projeto"
    echo "  add repo      - Adicionar o repositório remoto com PAT"
    echo "  help          - Mostrar esta ajuda"
    echo ""
    exit 0
}

## Função principal

main() {
    if [ -z "$GUM" ]; then
        install_gum
        GUM=$(command -v gum)
    fi

    CMD_NAME="shikan"
    local alias_path="$HOME/.local/bin/$CMD_NAME"
    
    if [[ ! -f "$alias_path" || ! -x "$alias_path" ]]; then
        if $GUM confirm "Alias 'shikan' não encontrado. Deseja instalar o alias para usar de qualquer lugar?"; then
            set_alias
        fi
    fi

    while true; do
        local action
        action=$($GUM choose "branch" "commit" "push" "merge" "deploy" "add repo" "help" "sair" --header "O que deseja fazer?")
        case $action in
            "branch")   branch ;;
            "commit")   commit ;;
            "push")     push ;;
            "merge")    merge ;;
            "deploy")   deploy ;;
            "add repo") add_remote ;;
            "help")     help ;;
            "sair")     break ;;
        esac
    done
}

main "$@"
