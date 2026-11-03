param(
    [ValidateSet('telemonitoramento_db', 'telemonitoramento_teste')]
    [string]$Banco = 'telemonitoramento_db',
    [int]$Porta = 0,
    [switch]$Compilar
)
$ErrorActionPreference = 'Stop'
if ($Porta -eq 0) { $Porta = if ($Banco -eq 'telemonitoramento_db') { 8080 } else { 8081 } }
if ($Porta -lt 1024 -or $Porta -gt 65535) { throw 'Informe uma porta entre 1024 e 65535.' }
if ($Banco -eq 'telemonitoramento_teste' -and $Porta -eq 8080) {
    throw 'A porta 8080 pertence ao banco original. Use a porta 8081 para testes.'
}
$repositorio = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$workspace = Split-Path $repositorio -Parent
$jar = Join-Path $repositorio 'target/TelemonitoramentoIdosos-1.0-SNAPSHOT.jar'
$runtime = Join-Path $workspace '.local-backups/runtime'
$url = "http://localhost:$Porta"
$urlBanco = "jdbc:postgresql://localhost:5432/$Banco"
$processos = @(Get-CimInstance Win32_Process -Filter "Name='java.exe'" | Where-Object {
    $_.CommandLine -match 'TelemonitoramentoIdosos[^\s]*\.jar' -and
    $_.CommandLine -match "--server.port=$Porta(\s|$)"
})
foreach ($processo in $processos) {
    if (!$Compilar -and $processo.CommandLine -match ([regex]::Escape($urlBanco) + '(\s|$)')) {
        try {
            Invoke-RestMethod "$url/auth/opcoes" -TimeoutSec 3 | Out-Null
            Write-Output "Backend disponível em $url usando $Banco (PID $($processo.ProcessId))."
            return
        } catch { throw 'O backend está iniciando ou não responde. Consulte os logs em .local-backups/runtime.' }
    }
    # Só substitui o backend do projeto identificado na porta solicitada.
    Stop-Process -Id $processo.ProcessId
    Wait-Process -Id $processo.ProcessId -Timeout 10 -ErrorAction SilentlyContinue
}
if ($Compilar -or !(Test-Path -LiteralPath $jar)) {
    $mavenAnterior = $env:MAVEN_OPTS
    try {
        $env:MAVEN_OPTS = '-Xmx256m -XX:MaxMetaspaceSize=192m -XX:ActiveProcessorCount=2'
        Push-Location $repositorio
        try { & '.\mvnw.cmd' package -q '-DskipTests' } finally { Pop-Location }
        if ($LASTEXITCODE -ne 0) { throw 'A compilação falhou. O backend não foi iniciado.' }
    } finally { $env:MAVEN_OPTS = $mavenAnterior }
}
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$argumentos = @('-Xmx320m', '-XX:MaxMetaspaceSize=192m', '-XX:ActiveProcessorCount=2',
    '-jar', "`"$jar`"", "--server.port=$Porta", "--spring.datasource.url=$urlBanco")
if ($Banco -eq 'telemonitoramento_teste') {
    # Testes não enviam notificações reais, mesmo se houver credenciais no ambiente.
    $argumentos += @('--firebase.credentials.path=', '--notificacao.twilio.from-sms=',
        '--notificacao.twilio.from-whatsapp=', '--notificacao.webhook.url=')
}
$novo = Start-Process -FilePath (Get-Command java.exe).Source -ArgumentList $argumentos `
    -WorkingDirectory $repositorio -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput (Join-Path $runtime "backend-$Porta.out.log") `
    -RedirectStandardError (Join-Path $runtime "backend-$Porta.err.log")
for ($tentativa = 0; $tentativa -lt 60; $tentativa++) {
    if (!(Get-Process -Id $novo.Id -ErrorAction SilentlyContinue)) {
        throw "O backend encerrou durante a inicialização. Consulte $runtime/backend-$Porta.err.log e backend-$Porta.out.log."
    }
    try {
        Invoke-RestMethod "$url/auth/opcoes" -TimeoutSec 2 | Out-Null
        Write-Output "Backend disponível em $url usando $Banco (PID $($novo.Id))."
        return
    } catch { Start-Sleep -Milliseconds 500 }
}
throw "O backend ainda não respondeu em $url. Consulte os logs em $runtime."
