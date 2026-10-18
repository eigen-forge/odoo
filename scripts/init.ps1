# Native Windows PowerShell setup (Windows PowerShell 5.1 and PowerShell 7+).
# Generates local Docker Compose secrets without installing Bash or OpenSSL.
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$secretsDir = Join-Path $projectRoot 'secrets'
$envExample = Join-Path $projectRoot '.env.example'
$envFile = Join-Path $projectRoot '.env'

if ([System.IO.File]::Exists($secretsDir)) {
    throw "Expected a directory at $secretsDir, but found a file."
}
if (-not [System.IO.Directory]::Exists($secretsDir)) {
    [void][System.IO.Directory]::CreateDirectory($secretsDir)
}

foreach ($name in @('postgresql_password', 'odoo_master_password')) {
    $file = Join-Path $secretsDir $name

    if ([System.IO.Directory]::Exists($file)) {
        throw "$file is a directory, not a secret file. Check it and remove it only if empty, then run this script again."
    }

    if ([System.IO.File]::Exists($file)) {
        $value = [System.IO.File]::ReadAllText($file).Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "$file exists but is empty. Fix it before starting Docker."
        }
        if ($value -notmatch '^[a-zA-Z0-9_-]+$') {
            throw "$file has unsupported characters. Use letters, digits, underscores or hyphens."
        }
        Write-Host "Kept existing secret: secrets/$name"
        continue
    }

    $bytes = [byte[]]::new(32)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    }
    finally {
        $rng.Dispose()
    }
    $value = [System.BitConverter]::ToString($bytes).Replace('-', '').ToLowerInvariant()
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($file, $value + "`n", $utf8NoBom)
    Write-Host "Created secret: secrets/$name"
}

if ([System.IO.Directory]::Exists($envFile)) {
    throw "$envFile is a directory, not a file."
}
if (-not [System.IO.File]::Exists($envFile)) {
    Copy-Item -LiteralPath $envExample -Destination $envFile
    Write-Host 'Created .env'
}

Write-Host 'Initialization complete. Run: docker compose up -d --build'
