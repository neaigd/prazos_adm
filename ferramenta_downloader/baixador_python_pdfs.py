#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import shutil
import logging
from datetime import datetime
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup

# --- Configuração ---
# Caminho relativo ao script dentro de ferramenta_downloader/
MARKDOWN_FILE = "pesquisa/pesquisa.md"
# Ajustado para salvar na pasta pdfs_baixados/ na raiz do projeto
OUTPUT_BASE_DIR_PREFIX = "../pdfs_baixados/downloads_python_"
# Número de tentativas para downloads
DOWNLOAD_TRIES = 2
# Timeout em segundos para requisições HTTP
REQUEST_TIMEOUT = 30

# --- Configuração do Logging ---
logging.basicConfig(level=logging.INFO,
                    format='[%(levelname)s] %(asctime)s (%(filename)s) - %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')

def sanitize_url_for_dirname(url_str: str) -> str:
    """
    Cria um nome de diretório seguro e curto a partir de uma URL.
    """
    name = re.sub(r'^https?://', '', url_str)
    name = re.sub(r'^www\.', '', name)
    name = name.replace('/', '_')
    name = re.sub(r'[^a-zA-Z0-9_-]', '', name)
    return name[:60]

def extract_urls_from_markdown_file(filepath: str) -> list:
    """
    Extrai URLs de um arquivo Markdown.
    """
    if not os.path.exists(filepath):
        logging.error(f"Arquivo de entrada '{filepath}' não encontrado. Verifique o caminho.")
        return []

    urls_found = set()
    url_pattern = re.compile(
        r'\[[^\]]*\]\((https?://[^\)]+)\)|'
        r'<\s*(https?://[^>]+)\s*>|'
        r'(https?://[^ <>"`\'()]+)',
        re.IGNORECASE
    )
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line_number, line in enumerate(f, 1):
                matches = url_pattern.findall(line)
                for match_tuple in matches:
                    url = next((m for m in match_tuple if m), None)
                    if url:
                        url = re.sub(r'[().,;:]*$', '', url)
                        urls_found.add(url)
    except Exception as e:
        logging.error(f"Erro ao ler o arquivo Markdown '{filepath}': {e}")
        return []
    
    return sorted(list(urls_found))

def download_file(url: str, target_dir: str, filename_from_header: bool = True) -> str | None:
    """
    Baixa um arquivo de uma URL para um diretório específico.
    Retorna o caminho do arquivo baixado ou None em caso de falha.
    """
    local_filename = None
    # Garante que o diretório de destino exista
    os.makedirs(target_dir, exist_ok=True)

    for attempt in range(DOWNLOAD_TRIES):
        try:
            logging.info(f"Tentativa {attempt + 1}/{DOWNLOAD_TRIES} de baixar: {url}")
            with requests.get(url, stream=True, timeout=REQUEST_TIMEOUT, allow_redirects=True) as r:
                r.raise_for_status()

                if filename_from_header:
                    content_disposition = r.headers.get('content-disposition')
                    if content_disposition:
                        fname_match = re.search(r'filename\*?=([\'"]?)([^"\';]+)\1', content_disposition, re.IGNORECASE)
                        if fname_match:
                            local_filename = fname_match.group(2)
                            if local_filename.lower().startswith("utf-8''"):
                                from urllib.parse import unquote
                                local_filename = unquote(local_filename[7:], encoding='utf-8')
                            elif local_filename.lower().startswith("iso-8859-1''"):
                                from urllib.parse import unquote
                                local_filename = unquote(local_filename[11:], encoding='iso-8859-1')
                
                if not local_filename:
                    parsed_url = urlparse(url)
                    local_filename = os.path.basename(parsed_url.path)
                    if not local_filename:
                        local_filename = parsed_url.netloc.replace('.', '_') + "_downloaded_file"
                        # Adicionar extensão se possível com base no content-type
                        content_type = r.headers.get('content-type', '').lower()
                        if 'pdf' in content_type:
                            local_filename += '.pdf'
                        elif 'html' in content_type:
                             local_filename += '.html' # Só para ter um nome

                local_filename = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', local_filename)
                local_filename = local_filename[:200]
                filepath = os.path.join(target_dir, local_filename)

                if os.path.exists(filepath):
                    logging.info(f"Arquivo '{filepath}' já existe. Pulando download (-nc).")
                    return filepath

                with open(filepath, 'wb') as f:
                    for chunk in r.iter_content(chunk_size=8192):
                        f.write(chunk)
                logging.info(f"Arquivo baixado com sucesso: {filepath}")
                return filepath
        except requests.exceptions.RequestException as e:
            logging.warning(f"Erro na tentativa {attempt + 1} de baixar {url}: {e}")
            if attempt + 1 == DOWNLOAD_TRIES:
                logging.error(f"Falha ao baixar {url} após {DOWNLOAD_TRIES} tentativas.")
                return None
        except Exception as e:
            logging.error(f"Erro inesperado ao baixar {url} na tentativa {attempt + 1}: {e}")
            if attempt + 1 == DOWNLOAD_TRIES:
                return None
    return None

def process_page_for_pdfs(page_url: str, output_dir_for_page: str):
    """
    Processa uma página web, encontra links PDF e os baixa.
    """
    logging.info(f"Procurando PDFs na página: {page_url}")
    pdfs_found_on_page = 0
    try:
        response = requests.get(page_url, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')

        for link_tag in soup.find_all('a', href=True):
            href = link_tag['href']
            if re.search(r'\.pdf([?#].*)?$', href, re.IGNORECASE):
                pdf_url = urljoin(page_url, href) # Constrói URL absoluta
                logging.info(f"Link PDF encontrado na página: {pdf_url}")
                if download_file(pdf_url, output_dir_for_page):
                    pdfs_found_on_page += 1
            
    except requests.exceptions.RequestException as e:
        logging.error(f"Erro ao acessar a página {page_url}: {e}")
    except Exception as e:
        logging.error(f"Erro ao processar a página {page_url}: {e}")
    
    if pdfs_found_on_page > 0:
        logging.info(f"{pdfs_found_on_page} PDF(s) baixados/encontrados de {page_url}.")
    else:
        logging.info(f"Nenhum PDF novo baixado de {page_url}.")
    
    return pdfs_found_on_page

def main():
    """
    Função principal do script.
    """
    logging.info("🚀 Iniciando script Python para baixar PDFs...")

    # Cria o diretório base de output principal (ex: ../pdfs_baixados/downloads_python_TIMESTAMP)
    # Este diretório está um nível ACIMA de onde o script roda
    main_output_folder = OUTPUT_BASE_DIR_PREFIX + datetime.now().strftime("%Y%m%d_%H%M%S")
    
    try:
        # O caminho para main_output_folder já inclui ../pdfs_baixados/
        os.makedirs(main_output_folder, exist_ok=True)
        # Loga o caminho absoluto para clareza de onde os arquivos estão indo
        logging.info(f"📂 Arquivos serão salvos em: {os.path.abspath(main_output_folder)}")
    except OSError as e:
        logging.error(f"❌ Falha ao criar diretório de saída principal '{main_output_folder}': {e}")
        return

    urls_to_process = extract_urls_from_markdown_file(MARKDOWN_FILE)

    if not urls_to_process:
        logging.info(f"ℹ️ Nenhuma URL válida encontrada em '{MARKDOWN_FILE}'. Encerrando.")
        if not os.listdir(main_output_folder): # Se main_output_folder está vazio
            try:
                os.rmdir(main_output_folder)
                logging.info(f"🗑️ Diretório de saída principal '{main_output_folder}' removido por estar vazio.")
            except OSError as e:
                logging.warning(f"Não foi possível remover o diretório de saída principal vazio '{main_output_folder}': {e}")
        return

    logging.info(f"🔎 Encontradas {len(urls_to_process)} URLs únicas para processar.")

    for url in urls_to_process:
        logging.info("----------------------------------------------------------------")
        logging.info(f"🔗 Processando URL: {url}")

        sanitized_name = sanitize_url_for_dirname(url)
        
        if re.search(r'\.pdf([?#].*)?$', url, re.IGNORECASE):
            logging.info("🎯 Link direto para PDF detectado.")
            target_subdir_for_url = os.path.join(main_output_folder, f"{sanitized_name}_DIRECTPDF")
            os.makedirs(target_subdir_for_url, exist_ok=True)
            
            downloaded_path = download_file(url, target_subdir_for_url)
            if not downloaded_path and not os.listdir(target_subdir_for_url):
                try:
                    os.rmdir(target_subdir_for_url)
                    logging.info(f"🗑️ Diretório '{target_subdir_for_url}' removido por estar vazio após falha no download.")
                except OSError as e:
                     logging.warning(f"Não foi possível remover o diretório vazio '{target_subdir_for_url}': {e}")
        else:
            logging.info(f"📄 Link de página detectado. Procurando PDFs dentro de: {url}")
            target_subdir_for_url = os.path.join(main_output_folder, f"{sanitized_name}_FROMPAGE")
            os.makedirs(target_subdir_for_url, exist_ok=True)

            pdfs_downloaded_count = process_page_for_pdfs(url, target_subdir_for_url)
            
            if pdfs_downloaded_count == 0 and not os.listdir(target_subdir_for_url):
                try:
                    os.rmdir(target_subdir_for_url)
                    logging.info(f"🗑️ Diretório '{target_subdir_for_url}' removido por estar vazio.")
                except OSError as e:
                    logging.warning(f"Não foi possível remover o diretório vazio '{target_subdir_for_url}': {e}")
    
    logging.info("----------------------------------------------------------------")
    logging.info(f"🎉 Script concluído! Verifique o diretório '{os.path.abspath(main_output_folder)}'.")
    try:
        if not os.listdir(main_output_folder):
            os.rmdir(main_output_folder)
            logging.info(f"🗑️ Diretório de saída principal final '{main_output_folder}' removido por estar vazio.")
    except OSError:
        pass

if __name__ == "__main__":
    # Define o diretório de trabalho para o diretório onde o script está localizado
    # Isso ajuda a resolver caminhos relativos como 'pesquisa/pesquisa.md' e '../pdfs_baixados/' corretamente
    # independentemente de onde o script é chamado.
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)
    main()
