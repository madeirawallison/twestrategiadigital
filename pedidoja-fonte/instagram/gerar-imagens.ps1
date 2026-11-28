# Gera os PNGs das artes com o Edge headless.
# O cardápio dentro dos aparelhos é o real (hamburgueriamadeira.pedidoja.com), carregado ao vivo,
# por isso a captura espera alguns segundos via protocolo de depuração (o --screenshot simples sai antes de carregar).
# Uso: pwsh pedidoja-fonte/instagram/gerar-imagens.ps1 [-Espera 15] [-Somente aparelhos]
param([int]$Espera = 15, [string[]]$Somente)
$aqui = $PSScriptRoot
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$porta = 9333
# arte, formato, largura, altura, transparente, destino
$trabalhos = @(
  @('mesa-qr', 'feed', 1080, 1350, $false, "$aqui\mesa-qr-feed.png"),
  @('mesa-qr', 'story', 1080, 1920, $false, "$aqui\mesa-qr-story.png"),
  @('cardapio-digital', 'feed', 1080, 1350, $false, "$aqui\cardapio-digital-feed.png"),
  @('cardapio-digital', 'story', 1080, 1920, $false, "$aqui\cardapio-digital-story.png"),
  @('aparelhos', 'site', 1600, 1000, $true, (Join-Path (Split-Path -Parent (Split-Path -Parent $aqui)) 'pedidoja\assets\aparelhos.webp'))
)

function Invoke-Cdp($ws, [int]$id, [string]$metodo, $params) {
  $msg = @{ id = $id; method = $metodo; params = $params } | ConvertTo-Json -Compress -Depth 5
  $seg = [ArraySegment[byte]]::new([Text.Encoding]::UTF8.GetBytes($msg))
  $ws.SendAsync($seg, 'Text', $true, [Threading.CancellationToken]::None).Wait()
  while ($true) {
    $ms = [IO.MemoryStream]::new(); $buf = [byte[]]::new(1MB)
    do { $r = $ws.ReceiveAsync([ArraySegment[byte]]::new($buf), [Threading.CancellationToken]::None).Result; $ms.Write($buf, 0, $r.Count) } until ($r.EndOfMessage)
    $resp = [Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
    if ($resp.id -eq $id) { return $resp.result }
  }
}

foreach ($t in $trabalhos) {
  $a, $f, $w, $h, $transp, $saida = $t
  if ($Somente -and $a -notin $Somente) { continue }
  $url = ([Uri](Join-Path $aqui "$a.html")).AbsoluteUri + "#$f"
  $perfil = Join-Path $env:TEMP "pedidoja-edge-ig-$f"
  $p = Start-Process -PassThru -FilePath $edge -ArgumentList @('--headless=new', '--disable-gpu', '--hide-scrollbars',
    "--user-data-dir=$perfil", "--remote-debugging-port=$porta", "--window-size=$w,$h", $url)
  Start-Sleep -Seconds $Espera
  $alvo = (Invoke-RestMethod "http://127.0.0.1:$porta/json") | Where-Object { $_.type -eq 'page' -and $_.url -like 'file:*' } | Select-Object -First 1
  $ws = [Net.WebSockets.ClientWebSocket]::new()
  $ws.ConnectAsync([Uri]$alvo.webSocketDebuggerUrl, [Threading.CancellationToken]::None).Wait()
  Invoke-Cdp $ws 1 'Emulation.setDeviceMetricsOverride' @{ width = $w; height = $h; deviceScaleFactor = 1; mobile = $false } | Out-Null
  if ($transp) { Invoke-Cdp $ws 2 'Emulation.setDefaultBackgroundColorOverride' @{ color = @{ r = 0; g = 0; b = 0; a = 0 } } | Out-Null }
  Start-Sleep -Seconds 2
  $fmt = if ($saida -like '*.webp') { 'webp' } else { 'png' }
  $img = Invoke-Cdp $ws 3 'Page.captureScreenshot' @{ format = $fmt; quality = 82; clip = @{ x = 0; y = 0; width = $w; height = $h; scale = 1 } }
  [IO.File]::WriteAllBytes($saida, [Convert]::FromBase64String($img.data))
  $ws.Dispose(); Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
  Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*$perfil*" } | Stop-Process -Force -ErrorAction SilentlyContinue
  Write-Host $saida
}
