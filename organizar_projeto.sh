#!/bin/bash

# Script para organizar a estrutura do projeto para a ferramenta de download de PDFs
# Este script deve ser executado a partir da raiz do seu projeto.

echo "-----------------------------------------------------"
echo "Iniciando a reorganização da estrutura do projeto..."
echo "-----------------------------------------------------"

# --- Diretório da Ferramenta ---
TOOL_DIR="ferramenta_downloader"
echo
echo "[PASSO 1/7] Verificando/Criando diretório da ferramenta: '$TOOL_DIR'..."
mkdir -p "$TOOL_DIR"
echo "Diretório '$TOOL_DIR' verificado/criado."

# --- Arquivos e Pastas a serem Movidos/Criados ---

# 1. Script Python
PYTHON_SCRIPT_ORIG="baixador_python_pdfs.py"
PYTHON_SCRIPT_DEST="$TOOL_DIR/baixador_python_pdfs.py"
echo
echo "[PASSO 2/7] Processando script Python '$PYTHON_SCRIPT_ORIG'..."
if [ -f "$PYTHON_SCRIPT_ORIG" ]; then
    if [ ! -f "$PYTHON_SCRIPT_DEST" ]; then
        echo "Movendo '$PYTHON_SCRIPT_ORIG' para '$PYTHON_SCRIPT_DEST'..."
        mv "$PYTHON_SCRIPT_ORIG" "$PYTHON_SCRIPT_DEST"
        echo "Movido com sucesso."
    else
        echo "AVISO: '$PYTHON_SCRIPT_DEST' já existe. '$PYTHON_SCRIPT_ORIG' na raiz não foi movido."
        echo "Por favor, verifique qual versão você deseja manter."
    fi
elif [ -f "$PYTHON_SCRIPT_DEST" ]; then
    echo "'$PYTHON_SCRIPT_DEST' já está no local correto."
else
    echo "AVISO: Script '$PYTHON_SCRIPT_ORIG' não encontrado na raiz e nem em '$PYTHON_SCRIPT_DEST'."
    echo "Criando placeholder vazio em '$PYTHON_SCRIPT_DEST'."
    touch "$PYTHON_SCRIPT_DEST"
fi

# 2. Pasta 'pesquisa'
PESQUISA_DIR_ORIG="pesquisa"
PESQUISA_DIR_DEST_PARENT="$TOOL_DIR"
PESQUISA_DIR_DEST_FULL="$TOOL_DIR/pesquisa" # Destino final: ferramenta_downloader/pesquisa

echo
echo "[PASSO 3/7] Processando diretório '$PESQUISA_DIR_ORIG'..."
if [ -d "$PESQUISA_DIR_ORIG" ]; then # Se 'pesquisa/' existe na raiz
    if [ ! -d "$PESQUISA_DIR_DEST_FULL" ]; then # E 'ferramenta_downloader/pesquisa/' NÃO existe
        echo "Movendo diretório '$PESQUISA_DIR_ORIG' para '$PESQUISA_DIR_DEST_PARENT/'..."
        mv "$PESQUISA_DIR_ORIG" "$PESQUISA_DIR_DEST_PARENT/" # Move 'pesquisa' para dentro de 'ferramenta_downloader'
        echo "Movido com sucesso."
    else # 'ferramenta_downloader/pesquisa/' JÁ existe
        echo "AVISO: Diretório '$PESQUISA_DIR_DEST_FULL' já existe."
        echo "O diretório '$PESQUISA_DIR_ORIG' na raiz não será movido para evitar conflitos."
        echo "Verifique se '$PESQUISA_DIR_DEST_FULL/pesquisa.md' contém os dados corretos."
        echo "Se desejar mesclar, faça-o manualmente."
    fi
elif [ -d "$PESQUISA_DIR_DEST_FULL" ]; then # 'pesquisa/' não está na raiz, mas já está em 'ferramenta_downloader/'
    echo "Diretório '$PESQUISA_DIR_DEST_FULL' já está no local correto."
else # 'pesquisa/' não existe em nenhum dos locais esperados
    echo "AVISO: Diretório '$PESQUISA_DIR_ORIG' não encontrado na raiz e '$PESQUISA_DIR_DEST_FULL' também não existe."
    echo "Criando '$PESQUISA_DIR_DEST_FULL' e '$PESQUISA_DIR_DEST_FULL/pesquisa.md' (vazio) como placeholder."
    mkdir -p "$PESQUISA_DIR_DEST_FULL"
    touch "$PESQUISA_DIR_DEST_FULL/pesquisa.md"
fi

# 3. Script Bash (placeholder)
BASH_SCRIPT_DEST="$TOOL_DIR/baixador_bash_pdfs.sh"
echo
echo "[PASSO 4/7] Verificando/Criando script Bash placeholder '$BASH_SCRIPT_DEST'..."
if [ ! -f "$BASH_SCRIPT_DEST" ]; then
    echo "Criando placeholder para '$BASH_SCRIPT_DEST'..."
    echo "#!/bin/bash" > "$BASH_SCRIPT_DEST"
    echo "# Script Bash para download de PDFs (a ser implementado)" >> "$BASH_SCRIPT_DEST"
    echo "# Execute a partir da pasta '$TOOL_DIR/'" >> "$BASH_SCRIPT_DEST"
    chmod +x "$BASH_SCRIPT_DEST" # Tornar executável
    echo "Placeholder criado."
else
    echo "'$BASH_SCRIPT_DEST' já existe."
fi

# 4. README da Ferramenta (placeholder)
README_TOOL_DEST="$TOOL_DIR/README_ferramenta.md"
echo
echo "[PASSO 5/7] Verificando/Criando README placeholder '$README_TOOL_DEST'..."
if [ ! -f "$README_TOOL_DEST" ]; then
    echo "Criando placeholder para '$README_TOOL_DEST'..."
    echo "# README para a Ferramenta de Download de PDFs" > "$README_TOOL_DEST"
    echo "" >> "$README_TOOL_DEST"
    echo "Este arquivo descreve como usar os scripts nesta pasta ('$TOOL_DIR')." >> "$README_TOOL_DEST"
    echo "Placeholder criado."
else
    echo "'$README_TOOL_DEST' já existe."
fi

# 5. requirements.txt
REQUIREMENTS_DEST="$TOOL_DIR/requirements.txt"
echo
echo "[PASSO 6/7] Verificando/Criando arquivo '$REQUIREMENTS_DEST'..."
if [ ! -f "$REQUIREMENTS_DEST" ]; then
    echo "Criando '$REQUIREMENTS_DEST'..."
    echo "requests" > "$REQUIREMENTS_DEST"
    echo "beautifulsoup4" >> "$REQUIREMENTS_DEST"
    echo "Arquivo '$REQUIREMENTS_DEST' criado."
else
    echo "'$REQUIREMENTS_DEST' já existe. Conteúdo não alterado."
fi

# --- Diretórios da Raiz (verificar existência) ---

# 6. Pasta pdfs_baixados
PDFS_DIR="pdfs_baixados"
echo
echo "[PASSO 7/7] Verificando/Criando diretório '$PDFS_DIR' na raiz..."
mkdir -p "$PDFS_DIR"
echo "Diretório '$PDFS_DIR' verificado/criado."
# Adicionar .gitkeep para que a pasta seja versionada mesmo se vazia, se ela estiver vazia
if [ ! -f "$PDFS_DIR/.gitkeep" ] && [ -z "$(ls -A "$PDFS_DIR" 2>/dev/null)" ]; then
    echo "Adicionando .gitkeep à pasta '$PDFS_DIR' vazia."
    touch "$PDFS_DIR/.gitkeep"
fi


# 7. index.html (apenas verificar, não criar se não existir)
INDEX_HTML="index.html"
echo
echo "[INFO] Verificando '$INDEX_HTML' na raiz..."
if [ -f "$INDEX_HTML" ]; then
    echo "'$INDEX_HTML' encontrado na raiz."
else
    echo "AVISO: '$INDEX_HTML' não encontrado na raiz. Crie-o se for parte do seu projeto."
fi

echo
echo "-----------------------------------------------------"
echo "Reorganização da estrutura do projeto concluída."
echo "-----------------------------------------------------"
echo "Estrutura final esperada (verifique os arquivos):"
echo "."
echo "├── $INDEX_HTML (se existia ou foi criado)"
echo "├── $PDFS_DIR/"
echo "│   └── (.gitkeep se a pasta estava vazia)"
echo "└── $TOOL_DIR/"
echo "    ├── $(basename "$PYTHON_SCRIPT_DEST")"
echo "    ├── $(basename "$BASH_SCRIPT_DEST")"
echo "    ├── $(basename "$README_TOOL_DEST")"
echo "    ├── $(basename "$REQUIREMENTS_DEST")"
echo "    └── pesquisa/"
echo "        └── pesquisa.md"
echo
echo "Por favor, revise as mensagens de AVISO acima, se houver alguma."
echo "Pode ser necessário mover manualmente o conteúdo de 'pesquisa.md' se o diretório de destino já existia."

