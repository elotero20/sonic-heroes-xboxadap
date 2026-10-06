<#
.SYNOPSIS
    Revierte lo que hizo instalar.ps1.

.DESCRIPTION
    - Quita los accesos directos "Sonic Heroes (Xbox)".
    - Quita el ajuste de escala DPI de Tsonic_win.exe.
    - Quita la configuración global de Reloaded-II (%APPDATA%) si apunta a esta instalación.
    - Manda a la Papelera la carpeta Reloaded-II (mods), las descargas y el lanzador jugar.ps1.
    - Con -BorrarJuego, manda también a la Papelera toda la carpeta del juego.

    El runtime .NET 9 Desktop no se desinstala (otros programas pueden usarlo). Si quieres quitarlo:
    Configuración > Aplicaciones > "Microsoft Windows Desktop Runtime - 9.0.x".

.EXAMPLE
    .\desinstalar.ps1

.EXAMPLE
    .\desinstalar.ps1 -BorrarJuego
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Destino = 'C:\Juegos\Sonic Heroes',
    [switch]$BorrarJuego
)

$ErrorActionPreference = 'Stop'
$Destino = [IO.Path]::GetFullPath($Destino.TrimEnd('\'))
$ExeJuego = Join-Path $Destino 'Tsonic_win.exe'
$Reloaded = Join-Path $Destino 'Reloaded-II'

function Write-Ok([string]$Texto) { Write-Host "    $Texto" -ForegroundColor Green }

function Remove-APapelera([string]$Ruta) {
    if (-not (Test-Path -LiteralPath $Ruta)) { return }
    Add-Type -AssemblyName Microsoft.VisualBasic
    if (Test-Path -LiteralPath $Ruta -PathType Container) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Ruta, 'OnlyErrorDialogs', 'SendToRecycleBin')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Ruta, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
    Write-Ok "A la Papelera: $Ruta"
}

if (Get-Process -Name 'Tsonic_win' -ErrorAction SilentlyContinue) { throw 'Sonic Heroes está abierto. Ciérralo primero.' }

foreach ($acceso in @((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Sonic Heroes (Xbox).lnk'), (Join-Path $Destino 'Jugar Sonic Heroes (Xbox).lnk'))) {
    if (Test-Path -LiteralPath $acceso) { Remove-Item -LiteralPath $acceso -Force; Write-Ok "Quitado: $acceso" }
}

$capas = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers', $true)
if ($capas) {
    try {
        $actual = [string]$capas.GetValue($ExeJuego, '')
        if ($actual -match 'HIGHDPIAWARE') {
            $resto = ($actual -replace '\s*HIGHDPIAWARE', '').Trim()
            if ($resto -eq '~' -or -not $resto) { $capas.DeleteValue($ExeJuego) } else { $capas.SetValue($ExeJuego, $resto) }
            Write-Ok 'Quitado el ajuste de escala DPI de Tsonic_win.exe'
        }
    } finally { $capas.Close() }
}

$rutaLoader = Join-Path $env:APPDATA 'Reloaded-Mod-Loader-II\ReloadedII.json'
if (Test-Path -LiteralPath $rutaLoader) {
    $launcher = [string](Get-Content -LiteralPath $rutaLoader -Raw | ConvertFrom-Json).LauncherPath
    if ($launcher.StartsWith($Reloaded, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $rutaLoader -Force
        Write-Ok "Quitado: $rutaLoader"
    }
}

if ($BorrarJuego) {
    Remove-APapelera $Destino
} else {
    Remove-APapelera $Reloaded
    Remove-APapelera (Join-Path $Destino '_descargas')
    Remove-APapelera (Join-Path $Destino 'jugar.ps1')
    Write-Host "    El juego sigue en $Destino (sin mods). Usa -BorrarJuego para quitarlo también."
}
Write-Host 'Listo.' -ForegroundColor Green
