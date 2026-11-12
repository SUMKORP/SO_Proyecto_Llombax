# Arquitectura en Podman

```text
AlmaLinux 9 (usuario SIN root)
│
├── Podman
│   ├── Red privada: so-proyecto-net
│   │   ├── so-navidrome  -> HTTP 4533 (puerto APP_PORT publicado)
│   │   │   ├── /music/musica   <= data/musica/ (solo lectura)
│   │   │   ├── /music/podcast  <= data/podcast/ (solo lectura)
│   │   │   └── /data           <= state/navidrome/ (SQLite/caché)
│   │   └── so-mariadb    -> puerto 3306 SOLO interno
│   │       └── /var/lib/mysql <= volumen Podman so-mariadb-data
│   └── Reinicio controlado con scripts Bash
│
└── ngrok (opcional) -> túnel HTTPS hacia localhost:APP_PORT
```

**Importante:** MariaDB NO es el motor de datos de Navidrome. El Compose
original añadía `ND_DATABASE_DRIVER=mysql` y un DSN MySQL, pero Navidrome
utiliza su propia base SQLite en `/data`. Se conserva MariaDB como servicio
auxiliar de laboratorio para respetar los componentes del proyecto entregado.

No se requiere daemon Docker, Docker Compose ni `podman-compose`.
Los scripts son comandos nativos `podman run/start/stop/exec`.
Los archivos `.mp3` de música y podcast están incluidos sin alteraciones.

## Persistencia
- `state/navidrome/`: base SQLite, usuarios, listas y caché.
- Volumen `so-mariadb-data`: base de datos de MariaDB.
- `data/musica`, `data/podcast`: bibliotecas multimedia originales.
- `backups/`: copias de SQL, SQLite/Navidrome y multimedia.

**Nota sobre repositorios de imágenes:** el prefijo `docker.io/` es una dirección
de registro OCI (Docker Hub). No significa que se use Docker: Podman descarga
imágenes OCI desde el mismo repositorio.
