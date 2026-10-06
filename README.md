# Sonic Heroes (PC) con control Xbox

Adaptación de **Sonic Heroes para PC (2004)** para jugarlo con un control **Xbox Series S/X**. También sirve con cualquier control XInput: Xbox One, Xbox 360, etc. Incluye:

- botones equivalentes a los del control de **GameCube**;
- gatillos analógicos para la cámara;
- teclado como alternativa cuando el control está apagado;
- pantalla ancha **16:9**;
- un análisis de seguridad de lo que se descargó.

> **Este repositorio no contiene el juego.** Solo tiene scripts, configuración y documentación. Los archivos del juego son propiedad de SEGA y nunca se suben aquí (ver `.gitignore`).

---

## ¿Qué hice?

### 1. Revisé que lo descargado no tuviera virus ✅

No encontré malware. Usé Microsoft Defender con firmas actualizadas, revisé a mano los 6 ejecutables y desarmé el instalador sin ejecutarlo. Los detalles y los hashes están en **[docs/REPORTE-SEGURIDAD.md](docs/REPORTE-SEGURIDAD.md)**. Lo más importante:

- No es la versión de GameCube, sino la **versión original de PC** (versión europea en inglés, v1.0.0.1). Por eso no hace falta emulador.
- **La extracción del `.7z` estaba incompleta:** faltaban 3,060 de 3,921 archivos (música, videos, texturas, textos). Así el juego no habría funcionado bien.
- Venían restos del DRM *SafeDisc*: `SECDRV.SYS` es un driver de 2004 con una vulnerabilidad conocida. No hacían nada, pero no los instalé.

### 2. Reinstalé el juego completo en `C:\Juegos\Sonic Heroes`

Lo extraje desde el `.7z` original, fuera de OneDrive para no subir ~1.5 GB a la nube del trabajo. Dejé fuera los restos de SafeDisc y los accesos directos del sitio de descarga.

### 3. Le añadí soporte real para el control Xbox

El juego de PC no es compatible con **XInput**, el sistema que usan los controles Xbox modernos. Además, **ignora los gatillos**. Como no hay código fuente (el juego es un `.exe` compilado en 2004), la solución que usa la comunidad es el cargador de mods **[Reloaded-II](https://github.com/Reloaded-Project/Reloaded-II)** con los mods de **[Sewer56](https://github.com/Sewer56)**:

| Mod | Para qué |
|---|---|
| [Heroes Controller Hook + XInput](https://github.com/Sewer56/Heroes.Controller.Hook.ReloadedII) | Lee el control Xbox y se lo pasa al juego, **incluidos los gatillos analógicos** para la cámara (como L/R en GameCube). Funciona hasta con 4 controles y reconoce el control aunque lo conectes con el juego abierto. |
| [Post Process](https://github.com/Sewer56/Heroes.Controller.Hook.ReloadedII/blob/master/README-POSTPROCESS.md) | Zona muerta del 12 % en los sticks, para que el personaje o la cámara no se muevan solos. |
| [Graphics Essentials](https://github.com/Sewer56/Heroes.Graphics.Essentials.ReloadedII) | Pantalla ancha 16:9 y ventana sin bordes. También acelera la carga de niveles y evita un crash al iniciar en Windows moderno. |

**El `.exe` del juego no se modifica.** Los mods se cargan en memoria cada vez que abres el juego con el acceso directo. Si abres `Tsonic_win.exe` directamente, el juego funciona como el original.

### 4. Ajustes de Windows (solo para este juego)

- **Escala DPI:** tu laptop usa escala al 125 %. Marqué el juego para que maneje su propia escala; si no, la ventana se sale de la pantalla. Es lo mismo que *Propiedades → Compatibilidad → Cambiar configuración de PPP alto → Invalidar… : Aplicación*.
- **Resolución automática:** el acceso directo abre el juego a la resolución de la **pantalla principal** de ese momento. Con el LG UltraGear: 2560×1440. Solo con la laptop: 1920×1080.
- Instalé **.NET 9 Desktop Runtime** (x64 y x86) de Microsoft, porque Reloaded-II lo necesita.

### 5. Limpieza

Mandé a la Papelera el instalador `Sonic-Heroes_Win_EN_Setup-Program.exe` y las imágenes de CD `Sonic_Heroes_Win_ROM_EN.7z`. No se necesitan y liberan 2.3 GB de OneDrive. El `.7z` con los archivos del juego se queda como respaldo.

La carpeta `Sonic_Heroes_Win_Files_EN\` de OneDrive (la extracción incompleta) ya no se usa y puedes borrarla.

### Estado de las pruebas

- ✅ Juego completo en `C:\Juegos\Sonic Heroes` (3,915 archivos) y `Tsonic_win.exe` en la versión compatible.
- ✅ .NET 9.0.20 (x64 y x86) instalado.
- ✅ El acceso directo abre el juego a través de Reloaded-II, y los **5 mods se cargan dentro del juego sin errores** (según el log de Reloaded-II).
- ✅ **Probado en el juego el 6 de octubre de 2026.** La ventana aparece en unos 8 segundos, sin bordes y a 2560×1440 en el monitor LG. **El control Xbox y el teclado funcionan.**

---

## 🎮 Cómo jugar

1. Conecta el control Xbox (USB, Bluetooth o adaptador). Puedes hacerlo antes o con el juego abierto.
2. Abre **"Sonic Heroes (Xbox)"** en el escritorio. También está en `C:\Juegos\Sonic Heroes\Jugar Sonic Heroes (Xbox).lnk`.
3. Para salir, usa el menú del juego o `Alt+F4`.

La pantalla de título dice *"PRESS ENTER KEY"* porque es la versión de PC. Con el control, pulsa **A** o **Menú (≡)**.

Los niveles 3D se ven en 16:9. Los menús 2D y los videos siguen en 4:3, con franjas a los lados; es normal.

### ⌨️ Teclado como alternativa

El teclado también funciona.

- **Con el control apagado o desconectado,** el teclado controla todo (Enter para empezar).
- **Con el control conectado,** funcionan los botones de los dos, pero para moverte mandan los sticks del control y las flechas no mueven al personaje.

Para cambiar las teclas, abre `C:\Juegos\Sonic Heroes\Launcher.exe` (el configurador original de SEGA) y ve a *Controller setting*. Después ciérralo y juega con el acceso directo de siempre.

El **mouse** está desactivado, porque en este juego es muy incómodo.

## Controles (estilo GameCube)

Cada botón está en la misma posición que en el control de GameCube:

| Acción | GameCube | Xbox Series |
|---|:---:|:---:|
| Moverse | Stick | Stick izquierdo |
| Saltar / Aceptar | A | **A** |
| Acción (ataque, *homing attack*, etc.) | B | **X** |
| Cambiar formación (derecha) / Atrás en menús | X | **B** |
| Cambiar formación (izquierda) / Omochao | Y | **Y** |
| Team Blast | Z | **RB** o **LB** |
| Girar cámara | L / R (analógicos) | **LT / RT** (analógicos) |
| Pausa | Start | **Menú (≡)** |
| Menús | Cruceta | Cruceta |

Para el modo de 2 jugadores, conecta un segundo control Xbox.

---

## Cambiar la configuración

La configuración vive en `C:\Juegos\Sonic Heroes\Reloaded-II\User\Mods\`. Hay dos formas de cambiarla.

**Con el script (recomendado).** Abre PowerShell en la carpeta de este repo:

```powershell
.\instalar.ps1 -Idioma Spanish        # menús y subtítulos en español (las voces siguen en inglés)
.\instalar.ps1 -PantallaCompleta      # pantalla completa exclusiva en vez de ventana sin bordes
.\instalar.ps1 -Ancho 1920 -Alto 1080 # resolución fija (desactiva el ajuste automático)
.\instalar.ps1 -RestablecerConfiguracion  # vuelve a los botones y valores de la carpeta config\
```

Ninguna opción vuelve a extraer el juego: lo que ya está hecho se omite.

**Desde Reloaded-II.** Abre `C:\Juegos\Sonic Heroes\Reloaded-II\Reloaded-II.exe`, selecciona *Sonic Heroes*, elige un mod y pulsa *Configure Mod*. Ahí puedes reasignar botones, cambiar la zona muerta, etc.

| Archivo en `config/` | Qué controla |
|---|---|
| `control-xbox-estilo-gamecube.json` | Botones del control Xbox. Los valores son nombres de XInput: `A`, `B`, `X`, `Y`, `LeftShoulder`, `RightShoulder`, `Back`, `Start`, `DPadUp`… Para asignar varios botones a una acción, sepáralos con coma. |
| `zona-muerta.json` | Zona muerta (%) de sticks y gatillos, invertir ejes, intercambiar gatillos. |
| `graficos.json` | Resolución, ventana o pantalla completa, idioma, volumen, sombras, subtítulos. |
| `controller-hook.json` | `UseOriginalInputs: true` (valor por defecto) permite usar también el teclado. Con `false`, el juego solo responde al control Xbox. |

## Instalar en otra PC

Requisitos: Windows 11 (su `tar.exe` sabe abrir `.7z`), conexión a internet y el archivo `Sonic_Heroes_Win_Files_EN.7z`.

1. Clona o descarga este repositorio. Pon `Sonic_Heroes_Win_Files_EN.7z` en la carpeta **que contiene** al repo, o indica la ruta con `-Archivo7z`.
2. Haz doble clic en **`instalar.cmd`** y acepta el aviso de Windows si pide instalar .NET.

El script se puede ejecutar las veces que quieras. Todas las descargas tienen versión y SHA-256 fijos.

## Desinstalar

- **`desinstalar.cmd`** quita los mods, los accesos directos y los ajustes de Windows. El juego queda como el original en `C:\Juegos\Sonic Heroes`.
- **`desinstalar.ps1 -BorrarJuego`** manda también el juego a la Papelera.
- .NET 9 no se quita automáticamente, porque otros programas pueden usarlo. Puedes desinstalarlo desde *Configuración → Aplicaciones*.

## Solución de problemas

| Problema | Solución |
|---|---|
| El control no responde | Ábrelo siempre con el acceso directo **"Sonic Heroes (Xbox)"**, no con `Tsonic_win.exe`. Comprueba que Windows ve el control en *Configuración → Bluetooth y dispositivos*. |
| El personaje o la cámara se mueven solos | Sube `DeadzonePercent` en `zona-muerta.json` (por ejemplo, a 18) y ejecuta `.\instalar.ps1 -RestablecerConfiguracion`. |
| El teclado no mueve al personaje | Apaga o desconecta el control: mientras está conectado, mandan sus sticks. |
| Una acción se activa dos veces o hay botones raros | Pon `UseOriginalInputs` en `false` en `config/controller-hook.json` y ejecuta `.\instalar.ps1 -RestablecerConfiguracion`. Esto desactiva el teclado. |
| El juego abre en la pantalla equivocada | El juego se abre en la **pantalla principal** de Windows (*Configuración → Pantalla → "Convertir en la pantalla principal"*). |
| Aparece "Falta .NET 9 Desktop Runtime" | Vuelve a ejecutar `instalar.cmd`. |
| Quiero ver qué hacen los mods | Hay logs en `%APPDATA%\Reloaded-Mod-Loader-II\Logs`. |

## Estructura del repositorio

```
instalar.ps1 / instalar.cmd        Instalación completa (repetible)
jugar.ps1                          Lanzador: ajusta la resolución y abre el juego con los mods
desinstalar.ps1 / desinstalar.cmd  Revierte la instalación
config/                            Botones, zona muerta, gráficos y opciones del hook
docs/REPORTE-SEGURIDAD.md          Análisis de seguridad con hashes
```

## Créditos

- **Sonic Heroes** © SEGA. Este repositorio no incluye ni distribuye archivos del juego.
- **Reloaded-II** de Sewer56 y colaboradores ([GPLv3](https://github.com/Reloaded-Project/Reloaded-II/blob/master/LICENSE)).
- **Heroes Controller Hook** y **Heroes Graphics Essentials** de Sewer56. Se descargan de sus *releases* oficiales y no se redistribuyen aquí.
