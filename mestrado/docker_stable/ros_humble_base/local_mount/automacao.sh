#!/bin/bash

# Tenta desativar um ambiente virtual ativo (ignora o erro se não houver nenhum)
deactivate 2>/dev/null || true

# Instala o gerenciador de pacotes 'uv'
curl -LsSf https://astral.sh/uv/install.sh | sh

# Carrega as variáveis de ambiente do uv
source .venv/bin/activate

# Entra na pasta braco_metodos e ativa o ambiente virtual
cd braco_metodos || { echo "Diretório braco_metodos não encontrado"; exit 1; }

rm -rf .venv || { echo "Diretório braco_metodos não encontrado"; exit 1; }
uv venv

source .venv/bin/activate

# Navega para a pasta Genesis
cd ../Genesis || { echo "Diretório Genesis não encontrado"; exit 1; }

# Instala o projeto atual em modo editável usando o uv
uv pip install -e .

# Instala o PyTorch (URL corrigida para a versão CUDA 12.1)
uv pip install torch --index-url https://download.pytorch.org/whl/cu126
