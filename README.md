# Proyecto Sistemas Operativos — Navidrome + MariaDB con Podman

Migración del proyecto originalmente preparado para Docker Compose en Windows.
**Esta versión ejecuta los contenedores con Podman nativo en AlmaLinux 9, sin
Docker Desktop ni Docker Compose.** Se incluyen los MP3 originales.

## Qué hace

- **Navidrome:** biblioteca web de música y podcasts, en `http://localhost:4533`.
- **MariaDB 10.11:** servicio auxiliar independiente, conservado del proyecto
  original para demostrar persistencia y manejo de contenedores.
- **ngrok (opcional):** expone la web por un túnel público mientras está activo.
- **Scripts Bash:** inician, detienen, recrean, revisan estado y realizan backups.

> **Corrección técnica importante:** Navidrome guarda su base (usuarios,
> playlists y metadatos) en SQLite dentro de `/data`; no la almacena en
> MariaDB. El `ND_DATABASE_DRIVER=mysql` y el DSN del Compose original no
> crean esa integración. Esta adaptación mantiene MariaDB como servicio
> aparte, sin afirmar una conexión inexistente.

## Requisitos

- AlmaLinux 9 o Linux con Podman instalado, usuario normal (rootless).
- Terminal Bash; acceso a Internet para descargar las imágenes la primera vez.
- Puerto local `4533` libre (o el `APP_PORT` elegido).
- ngrok solo si necesitas acceso remoto.

En AlmaLinux 9:

```bash
sudo dnf install -y podman tar curl
podman --version
podman info
```

No se requiere instalar Docker ni `podman-compose`.

## Inicio rápido

Desde la raíz de la carpeta de este proyecto:

```bash
cp .env.example .env
nano .env            # CAMBIA AMBAS CONTRASEÑAS
chmod 600 .env
chmod +x scripts/*.sh
./scripts/start.sh
```

Abre `http://localhost:4533` en el navegador **del equipo donde corre
Podman** y crea tu usuario administrador de Navidrome. En EC2 remoto, usa
un túnel SSH a `localhost` o, opcionalmente, ngrok; no expongas la web sin
configurar seguridad/autenticación.

Si modificas el puerto de `.env`, vuelve a crear los contenedores con
`./scripts/reset.sh`; `stop.sh` por sí solo no cambia el puerto configurado.

## Comandos principales

| Acción | Comando |
|---|---|
| Arrancar o reanudar servicios | `./scripts/start.sh` |
| Ver estado | `./scripts/status.sh` |
| Consultar logs Navidrome | `podman logs -f so-navidrome` |
| Consultar logs MariaDB | `podman logs -f so-mariadb` |
| Detener sin borrar datos | `./scripts/stop.sh` |
| Recrear para aplicar `.env` | `./scripts/reset.sh` |
| Backup SQL + SQLite + música | `./scripts/backup.sh` |
| Abrir túnel ngrok | `./scripts/web.sh` |

Los comandos anteriores se ejecutan **sin `sudo`**.

## Música y podcasts

Se incluyen todos los audios del archivo original:

```text
data/musica/*.mp3
     /podcast/*.mp3
```

Se montan **en solo lectura** en `/music/musica` y `/music/podcast`;
`ND_MUSICFOLDER=/music` permite que Navidrome escanee ambas carpetas. La
base de Navidrome se guarda de forma persistente en `state/navidrome/`.

## Respaldos y datos

`./scripts/backup.sh` genera una carpeta `backups/backup_FECHA/` con:

1. `mariadb.sql` — copia del servicio MariaDB independiente.
2. `navidrome-data.tar.gz` — datos SQLite, usuarios y listas (requiere parar
   brevemente Navidrome para garantizar consistencia).
3. `bibliotecas.tar.gz` — música y podcasts originales.

El script vuelve a arrancar Navidrome si estaba ejecutándose. **No borres**
el volumen `so-mariadb-data` ni `state/navidrome/` si necesitas conservar
usuarios y listas. No subas `.env`, `backups/` ni `state/` a Git.

## Acceso remoto con ngrok (opcional)

1. Instala ngrok y vincula tu token mediante `ngrok config add-authtoken ...`.
2. Mantén Navidrome encendido (`./scripts/start.sh`).
3. Ejecuta `./scripts/web.sh` y utiliza la URL HTTPS temporal mostrada.
4. Presiona `Ctrl+C` para cerrar el túnel.

Un túnel público permite el acceso de terceros que conozcan la dirección:
configura una contraseña robusta del administrador y evita compartir
públicamente el enlace. Solo publica contenidos con derechos de distribución.

## Arquitectura y diferencias

```text
Navegador -> localhost:APP_PORT -> Podman so-navidrome
                                     ├── data/musica/     (ro)
                                     ├── data/podcast/   (ro)
                                     └── state/navidrome (SQLite)

Podman so-mariadb -> volumen persistente so-mariadb-data
   (independiente de Navidrome; sin puerto público)
```

- Las imágenes siguen alojadas en el registro **docker.io**, compatible con
  Podman; usar ese dominio **no significa utilizar Docker Engine**.
- No se necesitan archivos `.bat`, WSL2 ni Docker Desktop en AlmaLinux 9.
- Los scripts usan red `so-proyecto-net`, volúmenes persistentes y montajes
  `:Z` para SELinux.
- `--restart unless-stopped` no equivale a habilitar un servicio systemd
  para arranque automático tras reboot. Para eso usa Podman Quadlet.

Documentación: `docs/arquitectura.md`, `docs/troubleshooting.md` y
`configs/service-config.yml`.

Documentación oficial: https://navidrome.org/docs/installation/podman/
