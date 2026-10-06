# Reporte de seguridad: Sonic Heroes (PC) descargado de OldGamesDownload

**Fecha:** 6 de octubre de 2026
**Veredicto:** ✅ no se encontró malware. Hay tres detalles que conviene atender (ver [Hallazgos](#hallazgos-que-no-son-malware)).

## Qué se analizó

| Archivo | Tamaño (bytes) | Origen (según `Zone.Identifier`) |
|---|---:|---|
| `Sonic-Heroes_Win_EN_Setup-Program.exe` | 1,250,212,231 | `d1.myabandonware.com` |
| `Sonic_Heroes_Win_Files_EN.7z` | 856,186,090 | `archive.org`, item `SonicHeroesPC` (enlazado desde oldgamesdownload.com) |
| `Sonic_Heroes_Win_ROM_EN.7z` | 1,141,299,983 | `archive.org`, mismo item |
| Carpeta `Sonic_Heroes_Win_Files_EN\` | 861 archivos | extraída del `.7z` anterior |

## Método

1. **Microsoft Defender** (firmas 1.459.576.0 del 06/10/2026): escaneo personalizado de toda la carpeta, incluido el contenido de los `.7z`, en modo solo-reporte. **0 amenazas.** El historial de detecciones de Defender estaba vacío.
2. **Inventario por contenido, no por extensión:** se revisó la cabecera de los 865 archivos para encontrar ejecutables disfrazados (cabecera `MZ`). Solo hay 6, todos esperados.
3. **Análisis estático de cada ejecutable:** cabeceras PE, secciones y entropía (para detectar empaquetadores u ofuscación), datos añadidos al final (*overlay*), firma Authenticode, tabla de importaciones (red, servicios, registro), cadenas sospechosas (URLs, `cmd`/`powershell`, persistencia en `Run`, minería) y ejecutables incrustados.
4. **Instalador desarmado sin ejecutarlo:** se decodificaron sus 14 bloques (formato Clickteam), incluyendo el script, la lista de archivos y las entradas de registro.
5. **Contenido de los `.7z`** listado y comparado con la carpeta extraída y con la lista del instalador.
6. **Versión del juego:** se comprobó que `Tsonic_win.exe` tiene inicios de función exactamente en las direcciones que usan los mods (`0x444F30`, `0x434FF0`, `0x4351A0`), es decir, que es la versión 1.0 estándar que usa la comunidad.

## Resultados por archivo

| Archivo | SHA-256 | Qué es | Resultado |
|---|---|---|---|
| `Tsonic_win.exe` | `63162D4E6BEF407DEE30C2DC5840539AD013459CAAE2019F46347CE4389C5B18` | El juego (SEGA, v1.0.0.1, compilado el 18/10/2004), sin el DRM SafeDisc. Solo importa DirectX 8, DirectInput 8, DirectSound, WinMM y lectura de registro. No usa red. | ✅ Limpio |
| `Launcher.exe` | `8A2C402EB1577999F42CB64CB6A0AE23090DF09C2148925C035BA5A395747FDA` | Configurador original de SEGA (MFC). Los recursos grandes son imágenes. Su única URL es `sega-europe.com`. | ✅ Limpio |
| `unsetup.exe` | `2AD5684B0C11AC740CEFBF4A535089282DC27377EB1B929609354090453D9B57` | Desinstalador original de SEGA. | ✅ Limpio |
| `unicows.dll` | `22F23CC65698741184EC34F46E6F69717644E0B5AABF5D5BD015101F2D72E56E` | Microsoft Layer for Unicode, con firma válida de Microsoft. | ✅ Limpio |
| `DrvMgt.dll` | `54E63822C01F1C969E629DB93251226EA7F036A689A0816B06E9C734CBB139C8` | Parte de SafeDisc: instala el driver `SECDRV`. El juego no la carga. | ⚠️ Resto de DRM (no se instaló) |
| `SECDRV.SYS` | `60A8B320AB7D3A329E60911986905C2CA193E83E637976F29C78670DC287A6A8` | Driver SafeDisc 4.00.060 (Macrovision, 2004), sin firma y con una vulnerabilidad conocida ([CVE-2007-5587](https://nvd.nist.gov/vuln/detail/CVE-2007-5587)). Está inerte: nada lo instala y Windows 10/11 lo bloquea. | ⚠️ Resto de DRM (no se instaló) |
| `Sonic-Heroes_Win_EN_Setup-Program.exe` | `2B0E5B8CF7D62B09817D64A0180BC6BE657E52B9EF22448C4AB8171A822EB425` | Instalador Clickteam Install Creator (2009) con los datos de versión de SEGA copiados. Su script contiene los textos originales de SEGA (licencia; instalación Full/Standard/Minimum en `Program Files\SEGA\SONICHEROES`). Instala los mismos 3,920 archivos del juego y solo escribe en el registro su entrada de desinstalación. No trae programas extra ni URLs propias. | ✅ Limpio, pero innecesario |
| 104 archivos `*.scr` | — | Scripts de cinemáticas del juego (datos). No son protectores de pantalla ni ejecutables. | ✅ Datos |

Los `.7z` solo contienen lo esperado: las imágenes de los 2 CDs (`.bin`/`.cue`) y los archivos del juego (3,919 archivos más 2 accesos directos `.url` del sitio).

## Hallazgos que no son malware

1. **La extracción del `.7z` estaba incompleta.** Faltaban 3,060 de 3,921 archivos: música, videos, texturas, fuentes y textos. El juego no habría funcionado bien. Se re-extrajo completo en `C:\Juegos\Sonic Heroes`.
2. **Restos de SafeDisc** (`SECDRV.SYS`, `DrvMgt.dll`). No se copiaron a la instalación nueva.
3. **La carpeta estaba dentro de OneDrive** (cuenta de trabajo). Eso implicaba subir ~3.2 GB a la nube. El juego quedó instalado fuera de OneDrive.

Nota: `Tsonic_win.exe` es el ejecutable original con el DRM SafeDisc retirado. Así se distribuye esta versión, que ya no se vende, y es la que usa la comunidad de mods.

## Descargas de este proyecto

Todo lo que descarga `instalar.ps1` viene de los *releases* oficiales en GitHub y se verifica con SHA-256 (los hashes están fijos en el script). Además, se escanearon con Defender: **0 amenazas**.

| Componente | SHA-256 |
|---|---|
| Reloaded-II 1.31.0 (`Release.zip`) | `C893DA3BA8596D9266826BD5CA8AACD25FE3B53D09314324AB65C7B618A05F8C` |
| Reloaded.SharedLib.Hooks 1.16.3 | `2B7C2E6118A3F1EB00A2E1E9105397B0D17A118A84596308C3A6A9FF3CB14B1B` |
| Heroes Controller Hook 2.2.1 | `C27FFBB4061A6CA6B97BC06DB5D2D47B38DF9BB1C114791E3D53E38DCFDCAEE7` |
| XInput for Controller Hook 2.2.1 | `4EF521A8CFEC96FA1D9D685D80B35CF2C5EBDCFAD7E68FB74E12138AA603DE6A` |
| Post Process for Controller Hook 2.3.1 | `B7F23B1470FCD7812ED2841C1C429537A71036FEFD8A265DBA84B17DA75CB13C` |
| Heroes Graphics Essentials 1.4.5 | `A9C996C0B88FC40DDCAE7BD84E9264BA48FC0BB2E5ABE9BB62A237263F4FA271` |

El runtime .NET 9 Desktop se descarga del enlace oficial de Microsoft (`aka.ms/dotnet/9.0/…`, que lleva a `builds.dotnet.microsoft.com`). El script verifica la firma digital de Microsoft antes de ejecutarlo.

## Limitaciones

Ningún análisis garantiza el 100 %. No se ejecutó ningún archivo del paquete en un entorno aislado (análisis dinámico). La conclusión se basa en tres cosas: el antivirus, el análisis estático y la coincidencia exacta con la versión conocida del juego.
