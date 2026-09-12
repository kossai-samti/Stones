[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')]
    [string]$Database = 'litha',

    [string]$PostgresUser = 'postgres',

    [string]$HostName = 'localhost',

    [ValidateRange(1, 65535)]
    [int]$Port = 5432
)

# Set PGPASSWORD in this PowerShell session before running this script if your
# PostgreSQL installation requires password authentication.  Keeping it out of
# this file prevents credentials from being committed with the application.
$psqlCandidates = @(
    (Get-Command psql.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source),
    'C:\Program Files\PostgreSQL\18\bin\psql.exe',
    'C:\Program Files\PostgreSQL\17\bin\psql.exe',
    'C:\Program Files\PostgreSQL\16\bin\psql.exe'
) | Where-Object { $_ -and (Test-Path $_) }

if (-not $psqlCandidates) {
    throw 'psql.exe was not found. Install PostgreSQL command-line tools or add its bin directory to PATH.'
}

$psql = $psqlCandidates[0]
$connectionArgs = @('-X', '-v', 'ON_ERROR_STOP=1', '-h', $HostName, '-p', $Port, '-U', $PostgresUser, '-d', 'postgres')
$exists = & $psql @connectionArgs '-qAt' '-c' "SELECT 1 FROM pg_database WHERE datname = '$Database';"

if ($LASTEXITCODE -ne 0) {
    throw 'Could not connect to PostgreSQL. Check that the service is running and that PGPASSWORD, user, host, and port are correct.'
}

if ($exists -eq '1') {
    Write-Host "Database '$Database' already exists. Nothing to do."
    exit 0
}

& $psql @connectionArgs '-c' "CREATE DATABASE `"$Database`";"
if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL could not create database '$Database'."
}

Write-Host "Created database '$Database'. Start the Spring API next; it will create/update the application tables."
