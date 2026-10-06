<#
.SYNOPSIS
    Instala Sonic Heroes (PC, 2004) listo para jugar con un control Xbox (XInput).

.DESCRIPTION
    Pasos (se puede ejecutar varias veces; lo que ya está hecho se omite):
      1. Extrae el juego completo desde Sonic_Heroes_Win_Files_EN.7z, sin los restos del DRM
         SafeDisc (SECDRV.SYS, DrvMgt.dll) ni los accesos directos/avisos del sitio de descarga.
      2. Descarga Reloaded-II y los mods de Sewer56 desde GitHub (versiones fijas, verificadas
         con SHA-256).
      3. Instala Reloaded-II en modo portable dentro de la carpeta del juego, con los mods.
      4. Configura: control Xbox con distribución estilo GameCube, zona muerta y pantalla 16:9.
      5. Le indica a Windows que el juego maneje su propia escala DPI (pantallas al 125 %, 150 %...).
      6. Instala .NET 9 Desktop Runtime x64/x86 si falta (Windows pedirá permiso de administrador).
      7. Copia el lanzador jugar.ps1 y crea el acceso directo "Sonic Heroes (Xbox)" en el escritorio
         y en la carpeta del juego.

    El ejecutable del juego NO se modifica: los mods se cargan en memoria al iniciar.

.PARAMETER Archivo7z
    Ruta de Sonic_Heroes_Win_Files_EN.7z. Si no se indica, se busca dentro de este repo, en la carpeta
    que lo contiene y en Descargas; si no aparece, se abre una ventana para elegirlo.
    En Windows 10 (cuyo tar.exe no abre .7z) se usa 7-Zip si está instalado.

.PARAMETER Destino
    Carpeta de instalación. Por defecto C:\Juegos\Sonic Heroes (fuera de OneDrive).

.PARAMETER Ancho
    Ancho de la ventana del juego. 0 = resolución de la pantalla principal.

.PARAMETER Alto
    Alto de la ventana del juego. 0 = resolución de la pantalla principal.

.PARAMETER Idioma
    Idioma de menús y subtítulos (las voces siempre son en inglés).

.PARAMETER PantallaCompleta
    Usa pantalla completa exclusiva en lugar de ventana sin bordes.

.PARAMETER SinModGraficos
    No instala Heroes Graphics Essentials (sin 16:9).

.PARAMETER RestablecerConfiguracion
    Reescribe la configuración de los mods con los valores de la carpeta config\ del repo,
    aunque ya exista (por ejemplo, si cambiaste los botones desde Reloaded-II).

.PARAMETER OmitirDotNet
    No instala .NET 9 Desktop Runtime aunque falte.

.PARAMETER SinAccesoDirecto
    No crea el acceso directo en el escritorio.

.EXAMPLE
    .\instalar.ps1

.EXAMPLE
    .\instalar.ps1 -Idioma Spanish

.EXAMPLE
    .\instalar.ps1 -Destino 'D:\Juegos\Sonic Heroes' -PantallaCompleta
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Archivo7z,
    [string]$Destino = 'C:\Juegos\Sonic Heroes',
    [int]$Ancho = 0,
    [int]$Alto = 0,
    [ValidateSet('English', 'Spanish', 'French', 'German', 'Italian', 'Japanese', 'Korean')]
    [string]$Idioma = 'English',
    [switch]$PantallaCompleta,
    [switch]$SinModGraficos,
    [switch]$RestablecerConfiguracion,
    [switch]$OmitirDotNet,
    [switch]$SinAccesoDirecto
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest es muy lento con barra de progreso en PS 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$RepoDir = $PSScriptRoot
$Destino = [IO.Path]::GetFullPath($Destino.TrimEnd('\'))
$ExeJuego = Join-Path $Destino 'Tsonic_win.exe'
$Reloaded = Join-Path $Destino 'Reloaded-II'
$CarpetaDescargas = Join-Path $Destino '_descargas'
$TarExe = Join-Path $env:SystemRoot 'System32\tar.exe'
$SieteZip = $null   # ruta de 7z.exe cuando tar.exe no puede abrir .7z (Windows 10)
# Con -Ancho/-Alto la resolución queda fija; si no, jugar.ps1 la ajusta a la pantalla principal en cada arranque.
$ResolucionFija = $PSBoundParameters.ContainsKey('Ancho') -or $PSBoundParameters.ContainsKey('Alto')

# Tsonic_win.exe 1.0.0.1 (sin SafeDisc): la versión cuyas direcciones de memoria usan los mods.
$Sha256JuegoCompatible = '63162D4E6BEF407DEE30C2DC5840539AD013459CAAE2019F46347CE4389C5B18'

# Archivos de juego que no se copian: aviso/acceso directo del sitio de descarga y restos del DRM SafeDisc
# (SECDRV.SYS es un driver de 2004 con una vulnerabilidad conocida, CVE-2007-5587; el juego no lo usa).
$ArchivosOmitidos = @('OldGamesDownload.url', 'readme.txt', 'SECDRV.SYS', 'DrvMgt.dll')

# Descargas fijas. Para actualizar un componente hay que cambiar URL y SHA-256 juntos.
# El orden importa: las dependencias van antes que los mods que las usan.
$Componentes = @(
    [pscustomobject]@{ Nombre = 'Reloaded-II 1.31.0'; Tipo = 'Loader'; Opcional = $false
        Archivo = 'Reloaded-II-1.31.0-Release.zip'
        Url = 'https://github.com/Reloaded-Project/Reloaded-II/releases/download/1.31.0/Release.zip'
        Sha256 = 'C893DA3BA8596D9266826BD5CA8AACD25FE3B53D09314324AB65C7B618A05F8C' }
    [pscustomobject]@{ Nombre = 'Reloaded.SharedLib.Hooks 1.16.3'; Tipo = 'Mod'; Opcional = $false
        Archivo = 'Reloaded.Hooks.ReloadedII1.16.3.7z'
        Url = 'https://github.com/Sewer56/Reloaded.SharedLib.Hooks.ReloadedII/releases/download/1.16.3/Reloaded.Hooks.ReloadedII1.16.3.7z'
        Sha256 = '2B7C2E6118A3F1EB00A2E1E9105397B0D17A118A84596308C3A6A9FF3CB14B1B' }
    [pscustomobject]@{ Nombre = 'Heroes Controller Hook 2.2.1'; Tipo = 'Mod'; Opcional = $false
        Archivo = 'Heroes.Controller.Hook2.2.1.7z'
        Url = 'https://github.com/Sewer56/Heroes.Controller.Hook.ReloadedII/releases/download/1.2.1/Heroes.Controller.Hook2.2.1.7z'
        Sha256 = 'C27FFBB4061A6CA6B97BC06DB5D2D47B38DF9BB1C114791E3D53E38DCFDCAEE7' }
    [pscustomobject]@{ Nombre = 'XInput for Controller Hook 2.2.1'; Tipo = 'Mod'; Opcional = $false
        Archivo = 'Heroes.Controller.Hook.XInput2.2.1.7z'
        Url = 'https://github.com/Sewer56/Heroes.Controller.Hook.ReloadedII/releases/download/1.2.1/Heroes.Controller.Hook.XInput2.2.1.7z'
        Sha256 = '4EF521A8CFEC96FA1D9D685D80B35CF2C5EBDCFAD7E68FB74E12138AA603DE6A' }
    [pscustomobject]@{ Nombre = 'Post Process for Controller Hook 2.3.1'; Tipo = 'Mod'; Opcional = $false
        Archivo = 'Heroes.Controller.Hook.PostProcess2.3.1.7z'
        Url = 'https://github.com/Sewer56/Heroes.Controller.Hook.ReloadedII/releases/download/1.2.1/Heroes.Controller.Hook.PostProcess2.3.1.7z'
        Sha256 = 'B7F23B1470FCD7812ED2841C1C429537A71036FEFD8A265DBA84B17DA75CB13C' }
    [pscustomobject]@{ Nombre = 'Heroes Graphics Essentials 1.4.5'; Tipo = 'Mod'; Opcional = $true
        Archivo = 'Heroes.Graphics.Essentials1.4.5.7z'
        Url = 'https://github.com/Sewer56/Heroes.Graphics.Essentials.ReloadedII/releases/download/1.4.5/Heroes.Graphics.Essentials1.4.5.7z'
        Sha256 = 'A9C996C0B88FC40DDCAE7BD84E9264BA48FC0BB2E5ABE9BB62A237263F4FA271' }
)

function Write-Paso([string]$Texto) { Write-Host ''; Write-Host "==> $Texto" -ForegroundColor Cyan }
function Write-Ok([string]$Texto) { Write-Host "    $Texto" -ForegroundColor Green }
function Write-Aviso([string]$Texto) { Write-Host "    AVISO: $Texto" -ForegroundColor Yellow }

# JSON en UTF-8 sin BOM (Reloaded-II y los mods usan System.Text.Json).
function Save-Json($Objeto, [string]$Ruta) {
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Ruta)
    [IO.File]::WriteAllText($Ruta, ($Objeto | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))
}

function Read-Json([string]$Ruta) { Get-Content -LiteralPath $Ruta -Raw -Encoding UTF8 | ConvertFrom-Json }

function Set-Propiedad($Objeto, [string]$Nombre, $Valor) {
    $Objeto | Add-Member -NotePropertyName $Nombre -NotePropertyValue $Valor -Force
}

function Expand-ConTar([string]$Archivo, [string]$Salida, [string[]]$Extra = @()) {
    $null = New-Item -ItemType Directory -Force -Path $Salida
    $argumentos = @('-xf', $Archivo, '-C', $Salida) + $Extra
    & $TarExe @argumentos
    if ($LASTEXITCODE -ne 0) { throw "No se pudo extraer $(Split-Path -Leaf $Archivo) (tar.exe terminó con código $LASTEXITCODE)." }
}

# Extrae un .zip o .7z completo: con 7-Zip si se está usando (Windows 10), si no con tar.exe.
function Expand-Archivo([string]$Archivo, [string]$Salida) {
    if ($SieteZip -and $Archivo.EndsWith('.7z')) {
        $null = New-Item -ItemType Directory -Force -Path $Salida
        & $SieteZip x -y -bso0 -bsp0 "-o$Salida" -- $Archivo
        if ($LASTEXITCODE -ne 0) { throw "No se pudo extraer $(Split-Path -Leaf $Archivo) (7-Zip terminó con código $LASTEXITCODE)." }
    } else {
        Expand-ConTar $Archivo $Salida
    }
}

# Contenido de un archivo dentro de un .zip/.7z, como texto.
function Read-DeArchivo([string]$Archivo, [string]$Interno) {
    if ($SieteZip -and $Archivo.EndsWith('.7z')) { return (& $SieteZip e -so -- $Archivo $Interno) -join "`n" }
    return (& $TarExe -xOf $Archivo $Interno) -join "`n"
}

function Get-SieteZip {
    foreach ($ruta in @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")) {
        if (Test-Path -LiteralPath $ruta) { return $ruta }
    }
    $comando = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($comando) { return $comando.Source }
    return $null
}

# Lista un .7z con 7-Zip en el mismo formato que "tar -tf": separador '/' y carpetas terminadas en '/'.
function Get-Listado7z([string]$Archivo) {
    $salida = & $SieteZip l -slt -ba -- $Archivo
    if ($LASTEXITCODE -ne 0) { throw "7-Zip no pudo leer $Archivo." }
    $lista = New-Object System.Collections.Generic.List[string]
    $ruta = $null; $esCarpeta = $false
    foreach ($linea in @($salida) + 'Path = ') {
        if ($linea.StartsWith('Path = ')) {
            if ($ruta) { if ($esCarpeta) { $lista.Add("$ruta/") } else { $lista.Add($ruta) } }
            $ruta = $linea.Substring(7).Replace('\', '/'); $esCarpeta = $false
        } elseif ($linea -eq 'Folder = +') {
            $esCarpeta = $true
        } elseif ($linea.StartsWith('Attributes = ')) {
            # Letras de Windows (R H S D A...) antes de los permisos Unix, p. ej. "RD_ drwxr-xr-x".
            $esCarpeta = $esCarpeta -or $linea.Substring(13).Split(' _'.ToCharArray())[0].Contains('D')
        }
    }
    return $lista
}

# Busca el .7z del juego dentro del repo, en la carpeta que lo contiene y en Descargas; si no está, pide elegirlo.
function Find-Archivo7z {
    $nombre = 'Sonic_Heroes_Win_Files_EN.7z'
    $descargas = $null
    try { $descargas = (New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path } catch { }
    foreach ($carpeta in @($RepoDir, (Split-Path -Parent $RepoDir), $descargas, (Join-Path $env:USERPROFILE 'Downloads'))) {
        if (-not $carpeta) { continue }
        $ruta = Join-Path $carpeta $nombre
        if (Test-Path -LiteralPath $ruta) { return $ruta }
    }
    Write-Host "    No encontré $nombre. Elígelo en la ventana que se abrió..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.Windows.Forms
    $dialogo = New-Object System.Windows.Forms.OpenFileDialog
    $dialogo.Title = "Elige el archivo del juego: $nombre"
    $dialogo.Filter = "Archivo del juego (*.7z)|*.7z|Todos los archivos (*.*)|*.*"
    if ($descargas) { $dialogo.InitialDirectory = $descargas }
    $ventana = New-Object System.Windows.Forms.Form -Property @{ TopMost = $true }   # para que el diálogo salga al frente
    try { $resultado = $dialogo.ShowDialog($ventana) } finally { $ventana.Dispose() }
    if ($resultado -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
    return $dialogo.FileName
}

function Get-Componente($Componente) {
    $ruta = Join-Path $CarpetaDescargas $Componente.Archivo
    if ((Test-Path -LiteralPath $ruta) -and (Get-FileHash -LiteralPath $ruta -Algorithm SHA256).Hash -eq $Componente.Sha256) {
        Write-Ok "$($Componente.Nombre): ya descargado"
        return $ruta
    }
    Write-Host "    Descargando $($Componente.Nombre)..."
    Invoke-WebRequest -Uri $Componente.Url -OutFile $ruta -UseBasicParsing
    $hash = (Get-FileHash -LiteralPath $ruta -Algorithm SHA256).Hash
    if ($hash -ne $Componente.Sha256) {
        Remove-Item -LiteralPath $ruta -Force
        throw "El SHA-256 de $($Componente.Archivo) no coincide (esperado $($Componente.Sha256), obtenido $hash). Se canceló por seguridad."
    }
    Write-Ok "$($Componente.Nombre): descargado y verificado (SHA-256)"
    return $ruta
}

# Resolución real de la pantalla principal, sin la escala DPI de Windows.
function Get-ResolucionPantalla {
    if (-not ('SonicHeroesXbox.Gdi' -as [type])) {
        Add-Type -Namespace SonicHeroesXbox -Name Gdi -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hWnd);
[DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
[DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
'@
    }
    $null = [SonicHeroesXbox.Gdi]::SetProcessDPIAware()
    $dc = [SonicHeroesXbox.Gdi]::GetDC([IntPtr]::Zero)
    try { return @([SonicHeroesXbox.Gdi]::GetDeviceCaps($dc, 118), [SonicHeroesXbox.Gdi]::GetDeviceCaps($dc, 117)) }  # DESKTOPHORZRES, DESKTOPVERTRES
    finally { $null = [SonicHeroesXbox.Gdi]::ReleaseDC([IntPtr]::Zero, $dc) }
}

# Reloaded-II 1.31 necesita Microsoft.WindowsDesktop.App 9.0.8 o superior (x64 para el launcher, x86 para el juego).
function Test-DesktopRuntime9([string]$ProgramFiles) {
    $carpeta = Join-Path $ProgramFiles 'dotnet\shared\Microsoft.WindowsDesktop.App'
    if (-not (Test-Path -LiteralPath $carpeta)) { return $false }
    return [bool](Get-ChildItem -LiteralPath $carpeta -Directory | Where-Object { $_.Name -match '^9\.0\.(\d+)$' -and [int]$Matches[1] -ge 8 })
}

# Instalador oficial de Microsoft (aka.ms apunta a la última 9.0.x). Se verifica su firma antes de ejecutarlo.
# No se usa winget: al tener ya la versión x64, winget cree que la x86 también está instalada.
function Install-DesktopRuntime9([string]$Arquitectura) {
    $instalador = Join-Path $CarpetaDescargas "windowsdesktop-runtime-9-win-$Arquitectura.exe"
    Invoke-WebRequest -Uri "https://aka.ms/dotnet/9.0/windowsdesktop-runtime-win-$Arquitectura.exe" -OutFile $instalador -UseBasicParsing
    $firma = Get-AuthenticodeSignature -LiteralPath $instalador
    if ($firma.Status -ne 'Valid' -or $firma.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
        Remove-Item -LiteralPath $instalador -Force
        throw "El instalador de .NET descargado no tiene una firma válida de Microsoft; no se ejecutó."
    }
    $proceso = Start-Process -FilePath $instalador -ArgumentList '/install', '/quiet', '/norestart' -Verb RunAs -Wait -PassThru
    Remove-Item -LiteralPath $instalador -Force
    if ($proceso.ExitCode -notin 0, 3010) { throw "El instalador de .NET terminó con código $($proceso.ExitCode)." }
}

# El acceso directo abre jugar.ps1 (ventana oculta), que ajusta la resolución y lanza Reloaded-II.
function New-AccesoDirecto([string]$Ruta) {
    $argumentos = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$(Join-Path $Destino 'jugar.ps1')`""
    if ($ResolucionFija) { $argumentos += ' -ResolucionFija' }
    $shell = New-Object -ComObject WScript.Shell
    $acceso = $shell.CreateShortcut($Ruta)
    $acceso.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $acceso.Arguments = $argumentos
    $acceso.WorkingDirectory = $Destino
    $acceso.IconLocation = "$ExeJuego,0"
    $acceso.WindowStyle = 7   # minimizada: evita el parpadeo de la consola
    $acceso.Description = 'Sonic Heroes con control Xbox (Reloaded-II)'
    $acceso.Save()
}

Write-Host 'Sonic Heroes (PC) + control Xbox' -ForegroundColor White
Write-Host "Destino: $Destino"

if (Get-Process -Name 'Tsonic_win' -ErrorAction SilentlyContinue) { throw 'Sonic Heroes está abierto. Ciérralo y vuelve a ejecutar el instalador.' }

# --- 1. Archivos del juego ------------------------------------------------------------------
Write-Paso '1/7  Archivos del juego'
if (-not $Archivo7z) { $Archivo7z = Find-Archivo7z }
if (-not $Archivo7z -or -not (Test-Path -LiteralPath $Archivo7z)) {
    throw 'No se encontró el archivo del juego (Sonic_Heroes_Win_Files_EN.7z). Ponlo en Descargas o indica la ruta con -Archivo7z.'
}
Write-Ok "Archivo del juego: $Archivo7z"
$listado = @()
if (Test-Path -LiteralPath $TarExe) {
    $listado = @(& $TarExe -tf $Archivo7z)
    if ($LASTEXITCODE -ne 0) { $listado = @() }
}
if ($listado.Count -eq 0) {
    # El tar.exe de Windows 10 no abre .7z: a partir de aquí se usa 7-Zip para todos los .7z.
    $SieteZip = Get-SieteZip
    if (-not $SieteZip) { throw 'Este Windows no puede abrir archivos .7z por sí solo. Instala 7-Zip (https://www.7-zip.org) y vuelve a ejecutar el instalador.' }
    Write-Ok "Se usará 7-Zip para abrir los .7z ($SieteZip)"
    $listado = @(Get-Listado7z $Archivo7z)
}

$prefijo = 'Sonic_Heroes_Win_Files_EN/Game Files/'
$esperados = @($listado | Where-Object { $_.StartsWith($prefijo) -and -not $_.EndsWith('/') } |
    ForEach-Object { $_.Substring($prefijo.Length) } | Where-Object { $ArchivosOmitidos -notcontains $_ })
if ($esperados.Count -lt 3000) { throw "El .7z no tiene la estructura esperada ($prefijo...)." }

$null = New-Item -ItemType Directory -Force -Path $Destino
$faltan = @($esperados | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Destino $_)) })
if ($faltan.Count -eq 0) {
    Write-Ok "El juego ya está completo ($($esperados.Count) archivos)"
} else {
    $libreGB = [math]::Round((Get-PSDrive -Name $Destino.Substring(0, 1)).Free / 1GB, 1)
    if ($libreGB -lt 2) { throw "Espacio libre insuficiente en $($Destino.Substring(0, 2)) ($libreGB GB; se necesitan ~2 GB)." }
    Write-Host "    Extrayendo $($esperados.Count) archivos (puede tardar unos minutos)..."
    if ($SieteZip) {
        # 7-Zip no puede quitar carpetas de la ruta al extraer: se extrae aparte y se mueve a su lugar.
        $temporal = Join-Path $Destino '_extraccion'
        Expand-Archivo $Archivo7z $temporal
        $origen = Join-Path $temporal $prefijo.TrimEnd('/').Replace('/', '\')
        $argumentosRobocopy = @($origen, $Destino, '/E', '/MOVE', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/XF') + $ArchivosOmitidos
        & robocopy.exe @argumentosRobocopy | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "No se pudieron mover los archivos del juego (robocopy terminó con código $LASTEXITCODE)." }
        Remove-Item -LiteralPath $temporal -Recurse -Force
    } else {
        $exclusiones = $ArchivosOmitidos | ForEach-Object { '--exclude'; "$prefijo$_" }
        Expand-ConTar $Archivo7z $Destino (@('--strip-components', '2') + $exclusiones + @($prefijo.TrimEnd('/')))
    }
    $faltan = @($esperados | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Destino $_)) })
    if ($faltan.Count -gt 0) { throw "Faltan $($faltan.Count) archivos después de extraer (por ejemplo: $($faltan[0]))." }
    Write-Ok "Extraídos $($esperados.Count) archivos"
}
foreach ($omitido in $ArchivosOmitidos) {
    $ruta = Join-Path $Destino $omitido
    if (Test-Path -LiteralPath $ruta) { Remove-Item -LiteralPath $ruta -Force; Write-Ok "Quitado: $omitido" }
}
$hashJuego = (Get-FileHash -LiteralPath $ExeJuego -Algorithm SHA256).Hash
if ($hashJuego -eq $Sha256JuegoCompatible) { Write-Ok 'Tsonic_win.exe es la versión 1.0 compatible con los mods' }
else { Write-Aviso "Tsonic_win.exe no es la versión probada (SHA-256 $hashJuego); los mods podrían no funcionar." }

# --- 2. Descargas ---------------------------------------------------------------------------
Write-Paso '2/7  Reloaded-II y mods (GitHub, verificados con SHA-256)'
$null = New-Item -ItemType Directory -Force -Path $CarpetaDescargas
$componentesUsados = @($Componentes | Where-Object { -not ($SinModGraficos -and $_.Opcional) })
$rutasDescargadas = @{}
foreach ($componente in $componentesUsados) { $rutasDescargadas[$componente.Archivo] = Get-Componente $componente }

# --- 3. Reloaded-II y mods ------------------------------------------------------------------
Write-Paso '3/7  Instalando Reloaded-II (modo portable) y mods'
$loader = $componentesUsados | Where-Object { $_.Tipo -eq 'Loader' }
Expand-Archivo $rutasDescargadas[$loader.Archivo] $Reloaded
# portable.txt hace que Reloaded-II guarde apps, mods y configuración dentro de su propia carpeta.
[IO.File]::WriteAllText((Join-Path $Reloaded 'portable.txt'), "Reloaded-II en modo portable.`r`n")
Write-Ok "$($loader.Nombre) en $Reloaded"

$modsInstalados = @()
foreach ($componente in ($componentesUsados | Where-Object { $_.Tipo -eq 'Mod' })) {
    $archivo = $rutasDescargadas[$componente.Archivo]
    $modConfig = Read-DeArchivo $archivo 'ModConfig.json' | ConvertFrom-Json
    $carpetaMod = Join-Path $Reloaded "Mods\$($modConfig.ModId)"
    if (Test-Path -LiteralPath $carpetaMod) { Remove-Item -LiteralPath $carpetaMod -Recurse -Force }
    Expand-Archivo $archivo $carpetaMod
    $modsInstalados += $modConfig.ModId
    Write-Ok "$($modConfig.ModName) $($modConfig.ModVersion)"
}

# --- 4. Configuración -----------------------------------------------------------------------
Write-Paso '4/7  Configuración: control Xbox (estilo GameCube), zona muerta y gráficos'
$configUsuario = Join-Path $Reloaded 'User\Mods'
$plantillas = Join-Path $RepoDir 'config'

# Configuración por puerto (jugador 1-4). No pisa cambios hechos desde Reloaded-II salvo -RestablecerConfiguracion.
$porPuerto = @(
    @{ ModId = 'sonicheroes.controller.hook'; Archivo = 'Controller-{0}.json'; Plantilla = 'controller-hook.json' }
    @{ ModId = 'sonicheroes.controller.hook.xinput'; Archivo = 'Controller{0}.json'; Plantilla = 'control-xbox-estilo-gamecube.json' }
    @{ ModId = 'sonicheroes.controller.hook.postprocess'; Archivo = 'Controller{0}.json'; Plantilla = 'zona-muerta.json' }
)
foreach ($config in $porPuerto) {
    $plantilla = Read-Json (Join-Path $plantillas $config.Plantilla)
    $escritos = 0
    foreach ($puerto in 0..3) {
        $ruta = Join-Path $configUsuario ("$($config.ModId)\" + ($config.Archivo -f $puerto))
        if ((Test-Path -LiteralPath $ruta) -and -not $RestablecerConfiguracion) { continue }
        Save-Json $plantilla $ruta
        $escritos++
    }
    if ($escritos -gt 0) { Write-Ok "$($config.ModId): $($config.Plantilla) aplicado a $escritos puerto(s)" }
    else { Write-Ok "$($config.ModId): se conserva la configuración existente" }
}

if (-not $SinModGraficos) {
    $rutaGraficos = Join-Path $configUsuario 'sonicheroes.essentials.graphics\Graphics.json'
    $nuevo = $RestablecerConfiguracion -or -not (Test-Path -LiteralPath $rutaGraficos)
    if ($nuevo) { $graficos = Read-Json (Join-Path $plantillas 'graficos.json') } else { $graficos = Read-Json $rutaGraficos }
    # En un archivo nuevo se aplican todos los valores; en uno existente, solo los parámetros indicados al ejecutar.
    if ($nuevo -or $PSBoundParameters.ContainsKey('Ancho') -or $PSBoundParameters.ContainsKey('Alto')) {
        if ($Ancho -le 0 -or $Alto -le 0) { $Ancho, $Alto = Get-ResolucionPantalla }
        Set-Propiedad $graficos 'Width' $Ancho
        Set-Propiedad $graficos 'Height' $Alto
    }
    if ($nuevo -or $PSBoundParameters.ContainsKey('Idioma')) { Set-Propiedad $graficos.DefaultSettings 'Language' $Idioma }
    if ($nuevo -or $PSBoundParameters.ContainsKey('PantallaCompleta')) { Set-Propiedad $graficos.DefaultSettings 'Fullscreen' ([bool]$PantallaCompleta) }
    Save-Json $graficos $rutaGraficos
    $modo = if ($graficos.DefaultSettings.Fullscreen) { 'pantalla completa' } else { 'ventana sin bordes' }
    Write-Ok "Gráficos: $($graficos.Width)x$($graficos.Height), $modo, idioma $($graficos.DefaultSettings.Language)"
}

# Aplicación registrada en Reloaded-II con los mods activados.
$carpetaApp = Join-Path $Reloaded 'Apps\tsonic_win.exe'
$rutaApp = Join-Path $carpetaApp 'AppConfig.json'
if ((Test-Path -LiteralPath $rutaApp) -and -not $RestablecerConfiguracion) {
    $app = Read-Json $rutaApp
    $activos = @(@($app.EnabledMods) + $modsInstalados | Where-Object { $_ } | Select-Object -Unique)
} else {
    $app = New-Object psobject
    $activos = $modsInstalados
}
if ($SinModGraficos) { $activos = @($activos | Where-Object { $_ -ne 'sonicheroes.essentials.graphics' }) }
Set-Propiedad $app 'AppId' 'tsonic_win.exe'
Set-Propiedad $app 'AppName' 'Sonic Heroes'
Set-Propiedad $app 'AppLocation' $ExeJuego
Set-Propiedad $app 'AppArguments' ''
Set-Propiedad $app 'AppIcon' 'Icon.png'
Set-Propiedad $app 'AutoInject' $false
Set-Propiedad $app 'EnabledMods' $activos
Set-Propiedad $app 'SortedMods' $activos
Set-Propiedad $app 'WorkingDirectory' $Destino
Set-Propiedad $app 'DontInject' $false
Save-Json $app $rutaApp
try {
    Add-Type -AssemblyName System.Drawing
    [Drawing.Icon]::ExtractAssociatedIcon($ExeJuego).ToBitmap().Save((Join-Path $carpetaApp 'Icon.png'), [Drawing.Imaging.ImageFormat]::Png)
} catch { Write-Aviso 'No se pudo extraer el icono del juego (no afecta al funcionamiento).' }
Write-Ok "Reloaded-II: Sonic Heroes registrado con $($activos.Count) mods activos"

# Configuración global de Reloaded-II (%APPDATA%). El bootstrapper inyectado en el juego la lee de ahí.
$rutaLoader = Join-Path $env:APPDATA 'Reloaded-Mod-Loader-II\ReloadedII.json'
if (Test-Path -LiteralPath $rutaLoader) {
    $loaderConfig = Read-Json $rutaLoader
    $otroLauncher = [string]$loaderConfig.LauncherPath
    if ($otroLauncher -and -not $otroLauncher.StartsWith($Reloaded, [StringComparison]::OrdinalIgnoreCase)) {
        Write-Aviso "Ya existía otro Reloaded-II ($otroLauncher). Al abrirlo de nuevo se reconfigura solo."
    }
} else { $loaderConfig = New-Object psobject }
$rutasLoader = [ordered]@{
    LauncherPath               = Join-Path $Reloaded 'Reloaded-II.exe'
    LoaderPath32               = Join-Path $Reloaded 'Loader\x86\Reloaded.Mod.Loader.dll'
    LoaderPath64               = Join-Path $Reloaded 'Loader\x64\Reloaded.Mod.Loader.dll'
    Bootstrapper32Path         = Join-Path $Reloaded 'Loader\x86\Bootstrapper\Reloaded.Mod.Loader.Bootstrapper.dll'
    Bootstrapper64Path         = Join-Path $Reloaded 'Loader\x64\Bootstrapper\Reloaded.Mod.Loader.Bootstrapper.dll'
    ApplicationConfigDirectory = Join-Path $Reloaded 'Apps'
    ModConfigDirectory         = Join-Path $Reloaded 'Mods'
    ModUserConfigDirectory     = Join-Path $Reloaded 'User\Mods'
    MiscConfigDirectory        = Join-Path $Reloaded 'User\Misc'
    PluginConfigDirectory      = Join-Path $Reloaded 'Plugins'
    UsePortableMode            = $true
    ShowConsole                = $false   # sin ventana de consola junto al juego; los logs siguen en %APPDATA%
}
foreach ($clave in $rutasLoader.Keys) { Set-Propiedad $loaderConfig $clave $rutasLoader[$clave] }
Save-Json $loaderConfig $rutaLoader
Write-Ok "Reloaded-II configurado ($rutaLoader)"

# --- 5. Escala DPI --------------------------------------------------------------------------
Write-Paso '5/7  Escala DPI de Windows para el juego'
# Igual que Propiedades > Compatibilidad > "Invalidar el comportamiento de escalado de PPP alto: Aplicación".
# Sin esto, con la escala de Windows al 125 % la ventana de 1920x1080 se sale de la pantalla.
$capas = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers')
try {
    $actual = [string]$capas.GetValue($ExeJuego, '')
    if ($actual -match 'HIGHDPIAWARE') { Write-Ok 'Ya estaba configurado' }
    else {
        if ($actual) { $valor = "$actual HIGHDPIAWARE" } else { $valor = '~ HIGHDPIAWARE' }
        $capas.SetValue($ExeJuego, $valor, [Microsoft.Win32.RegistryValueKind]::String)
        Write-Ok 'Tsonic_win.exe maneja su propia escala DPI (solo afecta a este juego)'
    }
} finally { $capas.Close() }

# --- 6. .NET ---------------------------------------------------------------------------------
Write-Paso '6/7  .NET 9 Desktop Runtime (requisito de Reloaded-II)'
foreach ($arquitectura in 'x64', 'x86') {
    if ($arquitectura -eq 'x64') { $programFiles = $env:ProgramFiles } else { $programFiles = ${env:ProgramFiles(x86)} }
    if (Test-DesktopRuntime9 $programFiles) { Write-Ok ".NET 9 Desktop Runtime $arquitectura ya está instalado"; continue }
    if ($OmitirDotNet) { Write-Aviso "Falta .NET 9 Desktop Runtime $arquitectura (omitido por -OmitirDotNet); Reloaded-II no funcionará sin él."; continue }
    Write-Host "    Instalando .NET 9 Desktop Runtime $arquitectura de Microsoft. Acepta el aviso de Windows (UAC)..." -ForegroundColor Yellow
    Install-DesktopRuntime9 $arquitectura
    if (-not (Test-DesktopRuntime9 $programFiles)) { throw "No se pudo instalar .NET 9 Desktop Runtime $arquitectura." }
    Write-Ok ".NET 9 Desktop Runtime $arquitectura instalado"
}

# --- 7. Accesos directos ----------------------------------------------------------------------
Write-Paso '7/7  Lanzador y accesos directos'
Copy-Item -LiteralPath (Join-Path $RepoDir 'jugar.ps1') -Destination (Join-Path $Destino 'jugar.ps1') -Force
Unblock-File -LiteralPath (Join-Path $Destino 'jugar.ps1')   # si el repo se bajó como ZIP, quita la marca "descargado de internet"
if ($ResolucionFija) { Write-Ok 'jugar.ps1 copiado (resolución fija)' } else { Write-Ok 'jugar.ps1 copiado (ajusta la resolución a la pantalla principal en cada arranque)' }
New-AccesoDirecto (Join-Path $Destino 'Jugar Sonic Heroes (Xbox).lnk')
Write-Ok "Creado en la carpeta del juego"
if (-not $SinAccesoDirecto) {
    New-AccesoDirecto (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Sonic Heroes (Xbox).lnk')
    Write-Ok 'Creado "Sonic Heroes (Xbox)" en el escritorio'
}

Write-Host ''
Write-Host 'Listo. Conecta el control Xbox y abre "Sonic Heroes (Xbox)".' -ForegroundColor Green
Write-Host @'

  Controles (estilo GameCube)
  ---------------------------------------------------------------
  Stick izquierdo ...... moverse          A ......... saltar / aceptar
  X .................... acción           B ......... formación der. / atrás
  Y .................... formación izq.   RB o LB ... Team Blast
  LT / RT .............. girar cámara     Menú (≡) .. pausa

  Teclado: funciona como alternativa con el control apagado (teclas en Launcher.exe).
'@
