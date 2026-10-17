<#
.SYNOPSIS
    Abre Sonic Heroes con los mods (Reloaded-II) en la pantalla elegida, a su resolución.

.DESCRIPTION
    Lo usan los accesos directos "Sonic Heroes" (instalar.ps1 lo copia a la carpeta del juego).
    Antes de abrir el juego ajusta la resolución a la pantalla elegida; cuando aparece la ventana
    del juego la mueve a esa pantalla y oculta la consola de registro de Reloaded-II.

.PARAMETER Pantalla
    1 = pantalla principal de Windows (por defecto), 2 = la siguiente, etc. (de izquierda a derecha).
    Si esa pantalla no está conectada, se usa la principal.

.PARAMETER ResolucionFija
    No toca la resolución guardada en Graphics.json ni mueve la ventana (se usa si instalaste con -Ancho/-Alto).
#>
#Requires -Version 5.1
[CmdletBinding()]
param([int]$Pantalla = 1, [switch]$ResolucionFija)

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
    if (-not (Test-Path -LiteralPath $Launcher)) { throw "No se encontró Reloaded-II en $Reloaded.`nVuelve a ejecutar instalar.cmd." }
    if (-not ((Test-DesktopRuntime9 $env:ProgramFiles) -and (Test-DesktopRuntime9 ${env:ProgramFiles(x86)}))) {
        throw "Falta .NET 9 Desktop Runtime (x64 y x86), que necesita Reloaded-II.`nVuelve a ejecutar instalar.cmd."
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -Namespace SonicHeroesXbox -Name Ventanas -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr contexto);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string clase, string titulo);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
public struct RECT { public int Left, Top, Right, Bottom; }
'@
    # El juego corre como "no consciente de DPI" (Windows lo escala): se usan sus mismas coordenadas
    # lógicas, p. ej. 1536x864 en una pantalla de 1920x1080 al 125 %.
    $null = [SonicHeroesXbox.Ventanas]::SetThreadDpiAwarenessContext([IntPtr](-1))   # DPI_AWARENESS_CONTEXT_UNAWARE

    # Pantallas: 1 = la principal, luego las demás de izquierda a derecha.
    $principal = [System.Windows.Forms.Screen]::PrimaryScreen
    $pantallas = @($principal) + @([System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary } | Sort-Object { $_.Bounds.X }, { $_.Bounds.Y })
    if ($Pantalla -lt 1 -or $Pantalla -gt $pantallas.Count) { $Pantalla = 1 }
    $area = $pantallas[$Pantalla - 1].Bounds

    if (-not $ResolucionFija -and (Test-Path -LiteralPath $RutaGraficos)) {
        $graficos = Get-Content -LiteralPath $RutaGraficos -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($graficos.Width -ne $area.Width -or $graficos.Height -ne $area.Height) {
            $graficos.Width = $area.Width
            $graficos.Height = $area.Height
            [IO.File]::WriteAllText($RutaGraficos, ($graficos | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))
        }
    }

    Start-Process -FilePath $Launcher -ArgumentList '--launch', "`"$ExeJuego`"" -WorkingDirectory $Reloaded

    # Espera la ventana del juego (hasta 90 s): oculta la consola de Reloaded-II y coloca la ventana.
    $limite = (Get-Date).AddSeconds(90)
    $colocadaDesde = $null
    while ((Get-Date) -lt $limite) {
        Start-Sleep -Milliseconds 500
        $consola = [SonicHeroesXbox.Ventanas]::FindWindow('ConsoleWindowClass', $ExeJuego)
        if ($consola -ne [IntPtr]::Zero) { $null = [SonicHeroesXbox.Ventanas]::ShowWindow($consola, 0) }
        $juego = [SonicHeroesXbox.Ventanas]::FindWindow('SonicHeroesPC-RW3.5', [NullString]::Value)   # $null llegaría como ""
        if ($juego -eq [IntPtr]::Zero) { continue }
        if ($ResolucionFija) { break }
        $r = New-Object SonicHeroesXbox.Ventanas+RECT
        $null = [SonicHeroesXbox.Ventanas]::GetWindowRect($juego, [ref]$r)
        if ($r.Left -ne $area.X -or $r.Top -ne $area.Y -or ($r.Right - $r.Left) -ne $area.Width -or ($r.Bottom - $r.Top) -ne $area.Height) {
            # SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED
            $null = [SonicHeroesXbox.Ventanas]::SetWindowPos($juego, [IntPtr]::Zero, $area.X, $area.Y, $area.Width, $area.Height, 0x0004 -bor 0x0010 -bor 0x0020)
            $colocadaDesde = $null
        } elseif (-not $colocadaDesde) {
            $colocadaDesde = Get-Date
        } elseif (((Get-Date) - $colocadaDesde).TotalSeconds -ge 5) {
            break   # lleva 5 s en su lugar: el juego ya no la va a mover
        }
    }
} catch {
    # El acceso directo abre esta ventana oculta: el error se muestra en un cuadro de diálogo.
    Add-Type -AssemblyName System.Windows.Forms
    $null = [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Sonic Heroes (Xbox)', 'OK', 'Error')
    exit 1
}
