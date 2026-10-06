<#
.SYNOPSIS
    Abre Sonic Heroes con los mods (Reloaded-II), ajustando antes la resolución a la pantalla principal.

.DESCRIPTION
    Lo usa el acceso directo "Sonic Heroes (Xbox)" (instalar.ps1 lo copia a la carpeta del juego).
    Si cambias de pantalla (laptop sola o con monitor externo), el juego se abre siempre a la
    resolución de la pantalla principal de ese momento.

.PARAMETER ResolucionFija
    No toca la resolución guardada en Graphics.json (se usa si instalaste con -Ancho/-Alto).
#>
#Requires -Version 5.1
[CmdletBinding()]
param([switch]$ResolucionFija)

$ErrorActionPreference = 'Stop'
$Destino = $PSScriptRoot
$Reloaded = Join-Path $Destino 'Reloaded-II'
$Launcher = Join-Path $Reloaded 'Reloaded-II.exe'
$ExeJuego = Join-Path $Destino 'Tsonic_win.exe'
$RutaGraficos = Join-Path $Reloaded 'User\Mods\sonicheroes.essentials.graphics\Graphics.json'

function Test-DesktopRuntime9([string]$ProgramFiles) {
    $carpeta = Join-Path $ProgramFiles 'dotnet\shared\Microsoft.WindowsDesktop.App'
    return (Test-Path -LiteralPath $carpeta) -and [bool](Get-ChildItem -LiteralPath $carpeta -Directory -Filter '9.0.*')
}

try {
    if (-not (Test-Path -LiteralPath $Launcher)) { throw "No se encontró Reloaded-II en $Reloaded.`nVuelve a ejecutar instalar.cmd del repo." }
    if (-not ((Test-DesktopRuntime9 $env:ProgramFiles) -and (Test-DesktopRuntime9 ${env:ProgramFiles(x86)}))) {
        throw "Falta .NET 9 Desktop Runtime (x64 y x86), que necesita Reloaded-II.`nVuelve a ejecutar instalar.cmd del repo."
    }

    if (-not $ResolucionFija -and (Test-Path -LiteralPath $RutaGraficos)) {
        Add-Type -Namespace SonicHeroesXbox -Name Pantalla -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hWnd);
[DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
[DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
'@
        $null = [SonicHeroesXbox.Pantalla]::SetProcessDPIAware()   # píxeles reales, sin la escala de Windows
        $dc = [SonicHeroesXbox.Pantalla]::GetDC([IntPtr]::Zero)
        try {
            $ancho = [SonicHeroesXbox.Pantalla]::GetDeviceCaps($dc, 118)   # DESKTOPHORZRES
            $alto = [SonicHeroesXbox.Pantalla]::GetDeviceCaps($dc, 117)    # DESKTOPVERTRES
        } finally { $null = [SonicHeroesXbox.Pantalla]::ReleaseDC([IntPtr]::Zero, $dc) }

        $graficos = Get-Content -LiteralPath $RutaGraficos -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($ancho -gt 0 -and $alto -gt 0 -and ($graficos.Width -ne $ancho -or $graficos.Height -ne $alto)) {
            $graficos.Width = $ancho
            $graficos.Height = $alto
            [IO.File]::WriteAllText($RutaGraficos, ($graficos | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))
        }
    }

    Start-Process -FilePath $Launcher -ArgumentList '--launch', "`"$ExeJuego`"" -WorkingDirectory $Reloaded
} catch {
    # El acceso directo abre esta ventana oculta: el error se muestra en un cuadro de diálogo.
    Add-Type -AssemblyName System.Windows.Forms
    $null = [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Sonic Heroes (Xbox)', 'OK', 'Error')
    exit 1
}
