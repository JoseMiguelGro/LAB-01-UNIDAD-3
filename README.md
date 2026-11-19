# LAB-01: Bitácoras y auditoría del dato en PostgreSQL

**Materia:** Gestión de Seguridad y Desempeño de Bases de Datos  
**Unidad:** III — Auditoría, trazabilidad y gobierno práctico de datos  
**Estudiante:** Guerrero Romero José Miguel
**Motor:** PostgreSQL 16.14  

## Despliegue del entorno
El laboratorio se desplegó mediante contenedor oficial `postgres:16` (PostgreSQL 16.14 sobre Debian 14.2.0 x86_64-pc-linux-gnu), configurando las reglas de `pg_hba.conf` para exigir autenticación `scram-sha-256` en conexiones TCP locales (`127.0.0.1/32` y `::1/128`).

## Estructura del repositorio
- `README.md`: Descripción del despliegue y estructura de entrega.
- `informe.md`: Informe técnico consolidado y respuestas a las preguntas de reflexión.
- `sql/`: Scripts SQL de configuración, auditoría y consultas de verificación (`01` a `06`).
- `evidencias/`: Documentación detallada por actividad (`01` a `16`), bitácora exportada sin secretos (`bitacora-lab01.log`) y su resumen de integridad (`bitacora-lab01.sha256`).
