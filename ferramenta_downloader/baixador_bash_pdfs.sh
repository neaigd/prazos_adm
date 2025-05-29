#!/bin/bash

# Configurações do Script
# Sai imediatamente se um comando sair com um status diferente de zero.
set -e # Removido -u para evitar problemas com variáveis não definidas em alguns contextos de find/wc
       # pipefail pode ser adicionado se necessário: set -eo pipefail

# --- Configuração ---
# Caminho relativo ao script dentro de ferramenta_downloader/
MARKDOWN_FILE="pesquisa/pesquisa.md"
# Ajustado para salvar na pasta pdfs_baixados/ na raiz do projeto
OUTPUT_BASE_DIR_PARENT="../pdfs_baixados" # Pasta pai para os downloads
OUTPUT_DIR_BASENAME="downloads_bash_$(date +%Y%m%d_%H%M%S)"

# Diretório de saída completo
OUTPUT_BASE_DIR="${OUTPUT_BASE_DIR_PARENT}/${OUTPUT_DIR_BASENAME}"

# --- Funções Auxiliares ---
log_info() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERRO] $(date +'%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Função para sanitizar URL para criar um nome de diretório seguro
sanitize_url_for_dirname() {
    local s_url="$1"
    echo "$s_url" | \
        sed -e 's|https\?://||' \
            -e 's|www\.||' \
            -e 's|/|_|g' \
            -e 's|[^a-zA-Z0-9_-]||g' | \
        cut -c1-60
}

# Função para extrair URLs do arquivo markdown (simplificada para Bash)
extract_urls_from_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        log_error "Arquivo de entrada '$file' não encontrado."
        return 1
    fi
    # Regex simplificada para Bash (grep -Eo para http/https)
    # Tenta pegar de [text](URL), <URL> e URLs soltas
    grep -Eoh \
        -e '\[[^]]*]\((https?://[^)]+)\)' \
        -e '<\s*(https?://[^>]+)\s*>' \
        -e 'https?://[^ <>"`()]+' \
        "$file" | \
    sed -E \
        -e 's/^\[[^]]*]\((.*)\)$/\1/' \
        -e 's/^<\s*(.*)\s*>$/\1/' | \
    sed -E 's/[().,;:]*$//' | \
    grep -E '^https?://' | \
    sort -u
}

# --- Script Principal ---
# Muda para o diretório do script para que os caminhos relativos funcionem
cd "$(dirname "$0")"

log_info "🚀 Iniciando script Bash para baixar PDFs..."

# 1. Criar Diretório de Saída Principal
mkdir -p "$OUTPUT_BASE_DIR"
if [ ! -d "$OUTPUT_BASE_DIR" ]; then
    log_error "❌ Falha ao criar diretório de saída: $OUTPUT_BASE_DIR"
    exit 1
fi
log_info "📂 Arquivos serão salvos em: $(cd "$OUTPUT_BASE_DIR" && pwd)" # Mostra caminho absoluto

# 2. Verificar se o arquivo markdown de entrada existe
if [ ! -f "$MARKDOWN_FILE" ]; then
    log_error "❌ Arquivo de entrada '$MARKDOWN_FILE' não encontrado."
    exit 1
fi

# 3. Extrair URLs do arquivo
extracted_urls=$(extract_urls_from_file "$MARKDOWN_FILE")

if [ -z "$extracted_urls" ]; then
    log_info "ℹ️ Nenhuma URL válida encontrada em '$MARKDOWN_FILE'."
    if [ -d "$OUTPUT_BASE_DIR" ] && [ -z "$(ls -A "$OUTPUT_BASE_DIR")" ]; then
        log_info "🗑️ Diretório de saída principal '$OUTPUT_BASE_DIR' está vazio. Removendo."
        rmdir "$OUTPUT_BASE_DIR" 2>/dev/null || true
    fi
    exit 0
fi

log_info "🔎 Encontradas $(echo "$extracted_urls" | wc -l | xargs) URLs únicas para processar."

echo "$extracted_urls" | while IFS= read -r url; do
    log_info "----------------------------------------------------------------"
    log_info "🔗 Processando URL: $url"
    
    url_sanitized_name=$(sanitize_url_for_dirname "$url")

    # A. VERIFICAR SE É UM LINK DIRETO PARA PDF
    if echo "$url" | grep -iqE '\.pdf([?#].*)?$'; then
        log_info "🎯 Link direto para PDF detectado."
        target_subdir_for_url="${OUTPUT_BASE_DIR}/${url_sanitized_name}_DIRECTPDF"
        mkdir -p "$target_subdir_for_url"

        log_info "📥 Baixando: $url para $target_subdir_for_url"
        wget_direct_status=0
        wget --content-disposition -P "$target_subdir_for_url" -nc -nv \
             --timeout=30 --tries=2 \
             "$url" || wget_direct_status=$?
        
        if [ $wget_direct_status -eq 0 ]; then
            # Verifica se algum arquivo foi realmente baixado/existe no diretório
            if find "$target_subdir_for_url" -maxdepth 1 -type f -print -quit 2>/dev/null | grep -q .; then
                log_info "✅ PDF baixado (ou já existia) em $target_subdir_for_url."
            else
                log_info "ℹ️ Comando wget para PDF direto executado, mas nenhum arquivo encontrado em $target_subdir_for_url."
            fi
        else
            log_error "⚠️ Falha ao baixar PDF direto (código: $wget_direct_status): $url"
            if [ -d "$target_subdir_for_url" ] && [ -z "$(ls -A "$target_subdir_for_url")" ]; then
                 log_info "🗑️ Diretório $target_subdir_for_url está vazio após falha. Removendo."
                 rmdir "$target_subdir_for_url" 2>/dev/null || true
            fi
        fi
    else
        # B. É UM LINK DE PÁGINA: TENTAR ENCONTRAR PDFs DENTRO DELA (usando wget -r como principal)
        log_info "📄 Link de página detectado. Procurando PDFs dentro de: $url"
        
        target_subdir_for_url_wget="${OUTPUT_BASE_DIR}/${url_sanitized_name}_FROMPAGE_WGET"
        mkdir -p "$target_subdir_for_url_wget"
        log_info "🔎 Tentativa (wget recursivo) para $url -> salvando em $target_subdir_for_url_wget"
        
        wget_recursive_cmd_status=0
        wget -r -l1 --no-parent -A.pdf --content-disposition -nd -nc -nv \
             --timeout=30 --tries=2 \
             -P "$target_subdir_for_url_wget" "$url" || wget_recursive_cmd_status=$?
        
        total_pdfs_in_page_wget_dir=$(find "$target_subdir_for_url_wget" -maxdepth 1 -type f -iname "*.pdf" 2>/dev/null | wc -l | xargs) # xargs para trim

        if [ "$wget_recursive_cmd_status" -eq 0 ] && [ "$total_pdfs_in_page_wget_dir" -gt 0 ]; then
            log_info "✅ Sucesso (wget recursivo): $total_pdfs_in_page_wget_dir PDF(s) encontrados/baixados de $url."
        else
            if [ "$wget_recursive_cmd_status" -ne 0 ]; then
                log_info "⚠️ Falha no comando wget recursivo (código: $wget_recursive_cmd_status) para $url."
            fi
            if [ "$total_pdfs_in_page_wget_dir" -eq 0 ]; then
                 log_info "ℹ️ Nenhum PDF encontrado por 'wget recursivo' em $url."
            fi
            # Opcional: adicionar fallback para lynx aqui se desejado, similar ao script Python.
            # Por simplicidade, este script Bash foca no wget -r para páginas.

            # Limpar diretório do wget se estiver vazio
            if [ "$total_pdfs_in_page_wget_dir" -eq 0 ] && [ -d "$target_subdir_for_url_wget" ] && [ -z "$(ls -A "$target_subdir_for_url_wget")" ]; then
                log_info "🗑️ Diretório wget $target_subdir_for_url_wget está vazio. Removendo."
                rmdir "$target_subdir_for_url_wget" 2>/dev/null || true
            fi
        fi
    fi
done <<< "$extracted_urls" # Usar here-string para alimentar o loop while

log_info "----------------------------------------------------------------"
log_info "🎉 Script Bash concluído! Verifique o diretório '$(cd "$OUTPUT_BASE_DIR" && pwd)'."
# Limpeza final do diretório de output base se estiver vazio
if [ -d "$OUTPUT_BASE_DIR" ] && [ -z "$(ls -A "$OUTPUT_BASE_DIR")" ]; then
    log_info "🗑️ Diretório de saída principal '$OUTPUT_BASE_DIR' está vazio. Removendo."
    rmdir "$OUTPUT_BASE_DIR" 2>/dev/null || true
fi
