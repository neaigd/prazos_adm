

# 🛠️ Ferramenta de Download de PDFs (Python e Bash) 🐍🔩

Esta ferramenta automatiza o download de arquivos PDF 📄 a partir de uma lista de URLs 🔗 fornecida em um arquivo Markdown. Ela é projetada para ser executada a partir da subpasta `ferramenta_downloader/` de um projeto maior.

## 🌟 Visão Geral

A ferramenta consiste em:

* 🐍 **Script Python (`baixador_python_pdfs.py`)**: Oferece uma funcionalidade de download mais robusta, incluindo parsing de HTML para encontrar PDFs em páginas web.
* 🔩 **(Opcional) Script Bash (`baixador_bash_pdfs.sh`)**: Para uma execução local mais simples, focada em links diretos ou usando `wget` recursivo.
* 📝 **Arquivo de entrada (`pesquisa/pesquisa.md`)**: Onde você lista as URLs a serem processadas.
* 📦 **Arquivo `requirements.txt`**: Para as dependências do script Python.

Os PDFs baixados 📥 são salvos na pasta `pdfs_baixados/` localizada na raiz do projeto (um nível acima desta pasta `ferramenta_downloader/`), para que possam ser facilmente acessados por outros componentes do projeto, como uma página `index.html`.

## 📁 Estrutura de Pastas do Projeto (Exemplo)

```
.
├── 📄 index.html                     # Página principal do projeto (exemplo)
├── 📂 pdfs_baixados/                 # ONDE OS PDFs SERÃO SALVOS
└── 📂 ferramenta_downloader/         # ESTA PASTA
    ├── 🐍 baixador_python_pdfs.py  # Script Python
    ├── 🔩 baixador_bash_pdfs.sh    # Script Bash (se incluído)
    ├── 📖 README_ferramenta.md     # Este arquivo
    ├── 📦 requirements.txt         # Dependências do Python
    └── 📂 pesquisa/
        └── 📝 pesquisa.md          # Arquivo de entrada com URLs
```

## ⚙️ Configuração e Uso (Script Python)

Siga estes passos para configurar e executar o script Python (`baixador_python_pdfs.py`):

### 1. ✅ Pré-requisitos

* Python 3.7 ou superior 🐍
* `pip` (gerenciador de pacotes Python) 📦

### 2. ✍️ Crie o arquivo `requirements.txt`

Dentro da pasta `ferramenta_downloader/`, crie um arquivo chamado `requirements.txt` com o seguinte conteúdo:

```txt
requests
beautifulsoup4
```

### 3. 🌍 Crie e Ative um Ambiente Virtual (Recomendado)

É uma boa prática usar ambientes virtuais para isolar as dependências.

* **No macOS e Linux** (execute a partir da pasta `ferramenta_downloader/`):

    ```bash
    # Navegue até a pasta da ferramenta
    # cd /caminho/para/seu/projeto/ferramenta_downloader

    # Crie o ambiente virtual (ex: chamado 'venv_tool')
    python3 -m venv venv_tool

    # Ative o ambiente virtual
    source venv_tool/bin/activate
    ```

* **No Windows** (execute a partir da pasta `ferramenta_downloader/`):

    ```bash
    # Navegue até a pasta da ferramenta
    # cd C:\caminho\para\seu\projeto\ferramenta_downloader

    # Crie o ambiente virtual (ex: chamado 'venv_tool')
    python -m venv venv_tool

    # Ative o ambiente virtual
    .\venv_tool\Scripts\activate
    ```

💡 Você saberá que o ambiente virtual está ativo porque o nome dele aparecerá no início do prompt do seu terminal (ex: `(venv_tool)`).

### 4. 📥 Instale as Dependências

Com o ambiente virtual ativo (e ainda dentro da pasta `ferramenta_downloader/`), instale as bibliotecas:

```bash
pip install -r requirements.txt
```

### 5.  подгото Prepare o Arquivo `pesquisa/pesquisa.md`

Dentro da pasta `ferramenta_downloader/`, crie uma subpasta `pesquisa/` e, dentro dela, um arquivo `pesquisa.md`. Este arquivo deve conter as URLs que você deseja processar.

📋 **Exemplo de conteúdo para `ferramenta_downloader/pesquisa/pesquisa.md`:**
*(Você precisará adicionar aqui o exemplo de conteúdo que faltou no texto original)*

---

