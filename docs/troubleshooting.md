# Solución de problemas

**1. `podman: command not found`**

```bash
sudo dnf install -y podman
podman info
```

**2. Falta `.env` o contraseñas de ejemplo**

```bash
cp .env.example .env
nano .env
chmod 600 .env
```

**3. Navidrome abre pero no aparecen canciones**

```bash
podman logs so-navidrome --tail 100
ls -la data/musica data/podcast
```

Revisa permisos de lectura y que los MP3 tengan metadatos correctos.
El contenedor escanea `/music`, que contiene las carpetas `musica` y `podcast`.

**4. Error de SELinux o permisos en `/data`**

Se usa el sufijo `:Z` para etiquetado SELinux de los volúmenes montados
además de `--userns keep-id` y el UID/GID del usuario normal. Los directorios
`data/` y `state/` deben ser propiedad del usuario que ejecuta Podman.
No ejecutes el proyecto con `sudo podman`; no mezcles rootful y rootless.

**5. Puerto ocupado**

Cambia `APP_PORT=4533` en `.env` por otro puerto (por ejemplo 4534) y ejecuta
`./scripts/reset.sh`. Luego usa ese puerto en ngrok o en el navegador.

**6. Base de datos MariaDB existente conserva credenciales antiguas**

Las variables `MARIADB_*` solo inicializan la base al crear el volumen por
primera vez. Editar `.env` no cambia usuarios ni claves existentes. No
elimines el volumen: perderías datos. Realiza el cambio con SQL y después
actualiza `.env`.

**7. Reinicio del servidor**

Vuelve a ejecutar `./scripts/start.sh` al iniciar sesión. `--restart` ayuda
con reinicios del contenedor cuando Podman lo administra, pero no garantiza
arranque tras un reboot sin integración con systemd. Para producción usa
Podman Quadlet y habilita un servicio de usuario con linger.

**8. La copia de seguridad detiene Navidrome**

Es intencional: SQLite necesita un respaldo consistente. El script reinicia
Navidrome después de archivar `state/navidrome`. La copia multimedia puede
duplicar más de 100 MB por ejecución.
