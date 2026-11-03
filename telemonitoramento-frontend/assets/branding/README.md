# Marca SeniorTrack

Os arquivos em `source/` são cópias integrais das imagens fornecidas pelo usuário.
As versões `logo.png` e `emblem.png` removem apenas margens externas e preparam
a arte para exibição; o desenho, os textos e as cores foram preservados.

Para recriar os favicons, os ícones web e os ícones Android, com Pillow instalado:

```sh
python scripts/prepare_branding.py
```

Os ícones `maskable` têm espaço adicional para os recortes feitos pelo sistema.
