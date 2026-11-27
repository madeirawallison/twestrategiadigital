# Pedido Já · site institucional (pedidoja.com)

O site publicado é a pasta `pedidoja/`: HTML estático, sem build, sem dependências
(só as fontes do Google Fonts). Esta pasta `pedidoja-fonte/` guarda o que gera o site.

## Editar

1. Altere o texto em `paginas/*.html` (cada arquivo começa com `caminho`, `titulo` e
   `descricao`, que viram o `<title>`, a description e o Open Graph da página).
   Cabeçalho, menu e rodapé ficam em `layout.html`; a lista de funcionalidades
   (menu, rodapé e cartões) fica no topo de `gerar.ps1`.
2. Visual: `../pedidoja/assets/estilo.css`. Menu e simulador: `../pedidoja/assets/site.js`.
3. Gere de novo: `pwsh pedidoja-fonte/gerar.ps1` (reescreve os `index.html`, `404.html`,
   `sitemap.xml` e `robots.txt` de `pedidoja/`).
4. Veja local: `pwsh pedidoja-fonte/servidor.ps1` e abra http://localhost:8099/

`og.html` é a origem da imagem de compartilhamento `pedidoja/assets/og.png` (1200x630),
gerada com o Edge headless.

## Páginas

| Endereço | Página |
|---|---|
| `/` | Início |
| `/funcionalidades/pedido-whatsapp/` | Pedido pelo WhatsApp com pagamento por link |
| `/funcionalidades/cardapio-digital/` | Cardápio digital |
| `/funcionalidades/mesas-qr-code/` | Mesas e QR Code |
| `/funcionalidades/garcom-e-totem/` | Garçom e Modo Totem |
| `/funcionalidades/balcao-pdv/` | Balcão / PDV |
| `/funcionalidades/cozinha/` | Cozinha |
| `/funcionalidades/caixa/` | Caixa |
| `/funcionalidades/filiais/` | Rede de unidades |
| `/funcionalidades/contabilidade/` | Contabilidade |
| `/planos/` | Planos e preços |
| `/perguntas-frequentes/` | Perguntas frequentes |
| `/contato/` | Contato |

## Publicação (proposta, ainda não feita)

Este repositório já é publicado pelo GitHub Pages em www.twestrategiadigital.com.br
(arquivo `CNAME` na raiz). Um site do GitHub Pages só aceita um domínio, então
pedidoja.com precisa de outra publicação. Recomendado, já que o domínio está na Cloudflare:

**Cloudflare Pages ligado a este repositório**
- Workers & Pages › Create › Pages › Connect to Git › `madeirawallison/twestrategiadigital`
- Branch de produção: `main` · Build command: vazio · Output directory: `pedidoja`
- Custom domains: `pedidoja.com` e `www.pedidoja.com` (a Cloudflare cria os registros DNS).
  Redirecionar `www` para o domínio sem `www` com uma Redirect Rule.
- Os subdomínios dos clientes (`cliente.pedidoja.com`) continuam apontando para o
  servidor do sistema: registros explícitos de `@` e `www` têm prioridade sobre um
  curinga `*`.
- Cada push no `main` que mexer em `pedidoja/` publica sozinho.

Efeito colateral: depois do merge no `main`, a pasta também aparece em
www.twestrategiadigital.com.br/pedidoja/. As páginas têm `canonical` apontando para
pedidoja.com, então o Google trata pedidoja.com como o endereço oficial.

Alternativa: repositório próprio `pedidoja` no GitHub com GitHub Pages e `CNAME`
pedidoja.com (registros A do GitHub Pages na Cloudflare, sem proxy laranja).
