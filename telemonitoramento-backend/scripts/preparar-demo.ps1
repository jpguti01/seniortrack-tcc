param(
    [Parameter(Mandatory = $true)][string]$PacienteEmail,
    [Parameter(Mandatory = $true)][string]$CuidadorEmail,
    [string]$Container = 'telemonitoramento-postgres',
    [string]$Banco = 'telemonitoramento_db',
    [switch]$SomenteValidar
)
$ErrorActionPreference = 'Stop'
$sqlPath = Join-Path $PSScriptRoot 'dados-demo.sql'
if (-not (Test-Path -LiteralPath $sqlPath)) { throw 'Arquivo SQL da demonstração não encontrado.' }
if (-not $SomenteValidar) {
    $workspace = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $backupFolder = Join-Path $workspace '.local-backups'
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    $backupName = 'seniortrack-antes-demo-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.dump'
    $backupFile = Join-Path $backupFolder $backupName
    & docker exec $Container pg_dump -U postgres -d $Banco -Fc -f "/tmp/$backupName"
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível criar o backup. Nenhum dado foi preenchido.' }
    & docker cp "${Container}:/tmp/$backupName" $backupFile
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível guardar o backup. Nenhum dado foi preenchido.' }
    Write-Output "Backup local: $backupFile"
}
& docker cp $sqlPath "${Container}:/tmp/seniortrack-dados-demo.sql"
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível preparar a carga SQL.' }
$aplicar = if ($SomenteValidar) { 'false' } else { 'true' }
& docker exec $Container psql -U postgres -d $Banco -X -v ON_ERROR_STOP=1 `
    -v "paciente_email=$PacienteEmail" -v "cuidador_email=$CuidadorEmail" `
    -v "aplicar=$aplicar" -f /tmp/seniortrack-dados-demo.sql
if ($LASTEXITCODE -ne 0) { throw 'Carga cancelada. A transação não foi confirmada.' }
if ($SomenteValidar) { Write-Output 'Validação concluída com ROLLBACK; os dados não foram gravados.' }
else { Write-Output 'Demonstração preparada. Os e-mails e as senhas das duas contas foram preservados.' }
