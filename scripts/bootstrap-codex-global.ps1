param(
    [string]$SourceRepo,
    [string]$RepoUrl = 'https://github.com/FYZAFH/superpowers-lite.git',
    [string]$RepoRef = 'main',
    [string]$CheckoutDir,
    [string]$CodexHome,
    [string]$InstallRoot
)

$ErrorActionPreference = 'Stop'

function Resolve-FullPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Default-CheckoutDir() {
    if ($env:LOCALAPPDATA) {
        return Join-Path $env:LOCALAPPDATA 'superpowers-lite\repo'
    }
    return Join-Path $HOME 'AppData\Local\superpowers-lite\repo'
}

function Get-PythonCommand() {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return @('py', '-3')
    }
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return @('python')
    }
    if (Get-Command python3 -ErrorAction SilentlyContinue) {
        return @('python3')
    }
    throw 'Python 3 is required to install Superpowers Lite for Codex on Windows.'
}

if (-not $CheckoutDir) {
    $CheckoutDir = Default-CheckoutDir
}

if ($SourceRepo) {
    $SourceRoot = Resolve-FullPath $SourceRepo
} else {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is required unless -SourceRepo is provided.'
    }

    $CheckoutDir = Resolve-FullPath $CheckoutDir
    $CheckoutParent = Split-Path -Parent $CheckoutDir
    if ($CheckoutParent) {
        New-Item -ItemType Directory -Force -Path $CheckoutParent | Out-Null
    }

    $GitDir = Join-Path $CheckoutDir '.git'
    if (Test-Path -LiteralPath $GitDir) {
        $CurrentOrigin = (& git -C $CheckoutDir config --get remote.origin.url 2>$null | Select-Object -First 1)
        if ($CurrentOrigin -and $CurrentOrigin.Trim() -ne $RepoUrl) {
            throw "checkout dir already points to a different origin: $CurrentOrigin"
        }

        & git -C $CheckoutDir remote set-url origin $RepoUrl
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        & git -C $CheckoutDir fetch --depth 1 origin $RepoRef
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        & git -C $CheckoutDir checkout --force FETCH_HEAD
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    } elseif (Test-Path -LiteralPath $CheckoutDir) {
        throw "checkout path exists and is not a git repo: $CheckoutDir"
    } else {
        & git clone --depth 1 --branch $RepoRef $RepoUrl $CheckoutDir
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }

    $SourceRoot = $CheckoutDir
}

$PythonCommand = Get-PythonCommand
$Installer = Join-Path $SourceRoot 'scripts\codex_installer.py'
$Arguments = @(
    $Installer,
    'install-global',
    '--repo-root',
    $SourceRoot
)

if ($CodexHome) {
    $Arguments += @('--codex-home', $CodexHome)
}
if ($InstallRoot) {
    $Arguments += @('--install-root', $InstallRoot)
}

$PythonArgs = @()
if ($PythonCommand.Count -gt 1) {
    $PythonArgs = $PythonCommand[1..($PythonCommand.Count - 1)]
}

& $PythonCommand[0] @PythonArgs @Arguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
