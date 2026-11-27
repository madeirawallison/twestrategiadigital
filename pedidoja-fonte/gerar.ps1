# Gera o site estático pedidoja/ a partir de layout.html + paginas/*.html
# Uso: pwsh pedidoja-fonte/gerar.ps1
$ErrorActionPreference = 'Stop'
$fonte = $PSScriptRoot
$saida = Join-Path (Split-Path -Parent $fonte) 'pedidoja'
$dominio = 'https://pedidoja.com/'
$utf8 = New-Object System.Text.UTF8Encoding($false)

# Funcionalidades: slug | ícone | nome | resumo
$funcs = @(
  @('pedido-whatsapp', '📲', 'Pedido pelo WhatsApp', 'Cardápio, conferência e pagamento por link'),
  @('cardapio-digital', '📖', 'Cardápio digital', 'Fotos, acréscimos com preço e destaques'),
  @('mesas-qr-code', '🔳', 'Mesas e QR Code', 'Pedido, garçom e conta pelo celular'),
  @('garcom-e-totem', '🧑‍🍳', 'Garçom e Modo Totem', 'Código por garçom e autoatendimento'),
  @('balcao-pdv', '🏪', 'Balcão / PDV', 'Venda rápida no balcão'),
  @('cozinha', '👨‍🍳', 'Cozinha', 'Tela de pedidos e impressão automática'),
  @('caixa', '💰', 'Caixa', 'Abertura, sangria e fechamento às cegas'),
  @('filiais', '🏢', 'Rede de unidades', 'Cardápio central para as filiais'),
  @('contabilidade', '🧮', 'Contabilidade', 'Pacote mensal para o contador')
)

function Sub-Menu($r) {
  ($funcs | ForEach-Object { "          <a href=""${r}funcionalidades/$($_[0])/""><span>$($_[1])</span><div><strong>$($_[2])</strong><small>$($_[3])</small></div></a>" }) -join "`n"
}
function Gaveta($r) {
  ($funcs | ForEach-Object { "      <a href=""${r}funcionalidades/$($_[0])/"">$($_[1]) $($_[2])</a>" }) -join "`n"
}
function Rodape($r) {
  ($funcs | ForEach-Object { "          <li><a href=""${r}funcionalidades/$($_[0])/"">$($_[2])</a></li>" }) -join "`n"
}
function Cartoes($r, $exceto) {
  ($funcs | Where-Object { $_[0] -ne $exceto } | ForEach-Object {
    "<a class=""cartao"" href=""${r}funcionalidades/$($_[0])/""><div class=""ico"">$($_[1])</div><h3>$($_[2])</h3><p>$($_[3]).</p><span class=""mais"">Ver como funciona →</span></a>"
  }) -join "`n"
}

$layout = [IO.File]::ReadAllText((Join-Path $fonte 'layout.html'), $utf8)
$mapa = @()
foreach ($arq in Get-ChildItem (Join-Path $fonte 'paginas') -Filter *.html) {
  $txt = [IO.File]::ReadAllText($arq.FullName, $utf8)
  if ($txt -notmatch '(?s)^\s*<!--(.*?)-->\s*(.*)$') { throw "Sem cabeçalho: $($arq.Name)" }
  $cab = $Matches[1]; $corpo = $Matches[2]
  $m = @{}
  foreach ($l in $cab -split "`r?`n") { if ($l -match '^\s*(\w+):\s*(.*?)\s*$') { $m[$Matches[1]] = $Matches[2] } }
  $caminho = $m['caminho']           # '' = home; 'funcionalidades/caixa/'; '404.html'
  if ($caminho -eq '404.html') { $r = '/'; $destino = Join-Path $saida '404.html' }
  else {
    $prof = @($caminho -split '/' | Where-Object { $_ }).Count
    $r = if ($prof -eq 0) { './' } else { '../' * $prof }
    $destino = Join-Path (Join-Path $saida $caminho) 'index.html'
    $mapa += $dominio + $caminho
  }
  $slug = ($caminho -replace '^funcionalidades/', '').TrimEnd('/')
  $corpo = $corpo.Replace('{{cartoes-funcionalidades}}', (Cartoes $r '')).Replace('{{outras-funcionalidades}}', (Cartoes $r $slug))
  $corpo = $corpo.Replace('{{outras}}', @"
<section class="sec-creme">
  <div class="wrap">
    <div class="cab"><span class="rotulo">Tudo conectado</span><h2>Funciona junto com o resto do sistema</h2><p class="lead">Mesmo cardápio, mesma cozinha, mesmo caixa e os mesmos relatórios para delivery, salão e balcão.</p></div>
    <div class="grade g4">
{{outras-funcionalidades}}
    </div>
  </div>
</section>
"@).Replace('{{outras-funcionalidades}}', (Cartoes $r $slug))
  $corpo = $corpo.Replace('{{chamada}}', @"
<section>
  <div class="wrap">
    <div class="chamada">
      <h2>Quer ver isso com o seu cardápio?</h2>
      <p>Fale com o nosso comercial: a gente mostra o sistema funcionando e monta a implantação de acordo com a sua operação.</p>
      <div class="acoes">
        <a class="btn btn-zap" href="https://wa.me/553140428010?text=Oi!%20Quero%20conhecer%20o%20Pedido%20J%C3%A1" target="_blank" rel="noopener">📲 Falar com o comercial</a>
        <a class="btn btn-linha" href="{{r}}planos/">Ver planos e preços</a>
      </div>
    </div>
  </div>
</section>
"@)
  $html = $layout.Replace('{{conteudo}}', $corpo.TrimEnd())
  $html = $html.Replace('{{menu-funcionalidades}}', (Sub-Menu $r)).Replace('{{gaveta-funcionalidades}}', (Gaveta $r)).Replace('{{rodape-funcionalidades}}', (Rodape $r))
  $html = $html.Replace('{{titulo}}', $m['titulo']).Replace('{{descricao}}', $m['descricao'])
  $html = $html.Replace('{{url}}', $dominio + ($(if ($caminho -eq '404.html') { '' } else { $caminho })))
  $html = $html.Replace('{{r}}', $r)
  if ($html -match '\{\{[\w-]+\}\}') { throw "Marcador sem valor em $($arq.Name): $($Matches[0])" }
  New-Item -ItemType Directory -Force (Split-Path -Parent $destino) | Out-Null
  [IO.File]::WriteAllText($destino, $html, $utf8)
  Write-Host "ok  $destino"
}

# sitemap e robots
$hoje = Get-Date -Format 'yyyy-MM-dd'
$urls = ($mapa | Sort-Object | ForEach-Object { "  <url><loc>$_</loc><lastmod>$hoje</lastmod></url>" }) -join "`n"
[IO.File]::WriteAllText((Join-Path $saida 'sitemap.xml'), "<?xml version=""1.0"" encoding=""UTF-8""?>`n<urlset xmlns=""http://www.sitemaps.org/schemas/sitemap/0.9"">`n$urls`n</urlset>`n", $utf8)
[IO.File]::WriteAllText((Join-Path $saida 'robots.txt'), "User-agent: *`nAllow: /`nSitemap: ${dominio}sitemap.xml`n", $utf8)
Write-Host "sitemap com $($mapa.Count) páginas"
