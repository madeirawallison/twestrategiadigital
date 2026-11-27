# Servidor estático local só para pré-visualizar o site (não é usado em produção)
# Uso: pwsh pedidoja-fonte/servidor.ps1 [porta]
param([int]$Porta = 8099)
$raiz = Join-Path (Split-Path -Parent $PSScriptRoot) 'pedidoja'
$tipos = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css'; '.js'='text/javascript'; '.svg'='image/svg+xml'; '.png'='image/png'; '.jpg'='image/jpeg'; '.mp4'='video/mp4'; '.pdf'='application/pdf'; '.xml'='application/xml'; '.txt'='text/plain' }
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:$Porta/")
$http.Start()
Write-Host "Pedido Já em http://localhost:$Porta/"
while ($http.IsListening) {
  $ctx = $http.GetContext()
  $caminho = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
  $arq = Join-Path $raiz $caminho
  if (Test-Path $arq -PathType Container) {
    if (-not $ctx.Request.Url.AbsolutePath.EndsWith('/')) { $ctx.Response.Redirect($ctx.Request.Url.AbsolutePath + '/'); $ctx.Response.Close(); continue }
    $arq = Join-Path $arq 'index.html'
  }
  $status = 200
  if (-not (Test-Path $arq -PathType Leaf)) { $arq = Join-Path $raiz '404.html'; $status = 404 }
  $bytes = [IO.File]::ReadAllBytes($arq)
  $ext = [IO.Path]::GetExtension($arq).ToLower()
  $ctx.Response.StatusCode = $status
  $ctx.Response.ContentType = $(if ($tipos[$ext]) { $tipos[$ext] } else { 'application/octet-stream' })
  $ctx.Response.ContentLength64 = $bytes.Length
  try { $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length) } catch {}
  $ctx.Response.Close()
}
