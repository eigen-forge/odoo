# Applies the versioned Odoo Sales module to exactly one existing database.
# PowerShell 5.1/7 on Windows + Docker Desktop / Compose v2.
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-zA-Z0-9_][a-zA-Z0-9_-]*$')]
    [string]$Database,

    [ValidateSet('install', 'upgrade')]
    [string]$Action = 'install'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path

Push-Location -LiteralPath $projectRoot
try {
    docker compose config --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Docker Compose configuration is invalid.' }

    $modeFlag = if ($Action -eq 'install') { '-i' } else { '-u' }
    Write-Host "Sales configuration: $Action on database $Database"
    Write-Warning 'The Odoo web container will stop briefly for ALL databases hosted by this Compose stack.'

    docker compose stop odoo
    if ($LASTEXITCODE -ne 0) { throw 'Could not stop Odoo safely.' }

    try {
        docker compose run --rm -T odoo -d $Database $modeFlag eigen_sales_config --stop-after-init --no-http
        if ($LASTEXITCODE -ne 0) { throw "Odoo module $Action failed for database $Database. Check output above." }
        Write-Host "Successfully applied Sales configuration to $Database."
    }
    finally {
        docker compose up -d odoo
        if ($LASTEXITCODE -ne 0) {
            Write-Warning 'Odoo could not restart automatically. Check docker compose ps and logs.'
        }
    }
}
finally {
    Pop-Location
}
