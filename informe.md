# Informe Técnico: LAB-01 — Bitácoras y auditoría del dato en PostgreSQL

---

## 1. Despliegue y situación inicial
El laboratorio se ejecutó sobre **PostgreSQL 16.14** desplegado mediante contenedor oficial (`postgres:16`), ajustando `pg_hba.conf` para exigir autenticación `scram-sha-256` en conexiones TCP (`127.0.0.1/32` y `::1/128`).

En su configuración por defecto, el motor presentaba `logging_collector = off`, `log_connections = off`, `log_disconnections = off`, `log_statement = 'none'` y `log_line_prefix = '%m [%p] '`. Bajo este estado inicial, el servidor delega `stderr` al entorno de despliegue y no conserva registro alguno de quién se conecta, desde qué dirección IP lo hace ni qué sentencias SQL ejecuta. Por ello, al simular el incidente de modificación del RFC de María García (`id = 3`) por parte de `app_ventas` (Actividad 3), fue imposible responder a Dirección quién realizó el cambio, cuándo ocurrió o qué valor existía previamente.

---

## 2. Configuración aplicada

| Parámetro | Valor configurado | Mecanismo de aplicación | Justificación técnica |
| :--- | :--- | :--- | :--- |
| `logging_collector` | `on` | Reinicio del servicio | Permite que PostgreSQL gestione sus propios archivos de bitácora en `log_directory`, independientes del contenedor o SO. |
| `log_connections` | `on` | Recarga (`pg_reload_conf()`) | Registra cada intento de conexión exitoso o fallido junto con el método de autenticación aplicado. |
| `log_disconnections` | `on` | Recarga (`pg_reload_conf()`) | Documenta el cierre de cada sesión y su duración total. |
| `log_line_prefix` | `'%m [%p] user=%u db=%d app=%a client=%h '` | Recarga (`pg_reload_conf()`) | Incorpora marca temporal UTC, PID, usuario de sesión, base de datos, aplicación cliente e IP de origen en cada línea. |
| `log_statement` | `'ddl'` → `'mod'` | Recarga (`pg_reload_conf()`) | En `'ddl'` captura cambios de estructura y privilegios; en `'mod'` incorpora `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE` y `COPY FROM` sin saturar con `SELECT`. |
| `shared_preload_libraries` *(Parte C)* | `'pgaudit'` | Reinicio del servicio | Carga la extensión `pgaudit` para auditar lecturas y escrituras dirigidas exclusivamente a columnas sensibles (`rfc`, `telefono`). |

---

## 3. Eventos observados e interpretados

1. **Configuración:** Al recargar con `pg_reload_conf()`, el proceso principal (`PID 1`) registró `LOG: parameter "log_statement" changed to "ddl"` (y posteriormente a `"mod"`), dejando traza incluso cuando la sentencia `ALTER SYSTEM` previa no se había registrado.
2. **Acceso:** Se diferenciaron intentos rechazados (`FATAL: password authentication failed` para `app_ventas` y `Role "usuario_inexistente" does not exist` en `DETAIL`) frente a conexiones exitosas (`connection authenticated` / `connection authorized` / `disconnection`) desde `client=127.0.0.1`.
3. **Privilegio:** Con `log_statement = 'ddl'` quedaron registradas las sentencias `REVOKE UPDATE ON clientes FROM soporte_ana` y `GRANT UPDATE ON clientes TO app_ventas`.
4. **Estructura:** Quedó registrada la alteración de esquema `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)`.
5. **Datos:** Con `log_statement = 'mod'` se registró `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` ejecutado por `user=app_ventas` desde `client=127.0.0.1` (`app=app-ventas-web`).
6. **Error:** Gracias a `log_min_error_statement = error`, se registró el intento denegado `DELETE FROM clientes WHERE id = 5` de `soporte_ana` (`ERROR: permission denied for table clientes`) y el intento fallido de eliminar un rol con dependencias (`DROP ROLE soporte_ana`).

---

## 4. Auditoría del dato
Para superar la limitación de la bitácora del servidor (que guarda la sentencia SQL pero no el estado previo de los registros), se creó el esquema protegido `auditoria` (sin acceso a `PUBLIC`) y la tabla `auditoria.cambios_clientes`, almacenando las imágenes completa anterior (`valores_antes`) y posterior (`valores_despues`) en formato `JSONB`.

La función disparadora `auditoria.registrar_cambio_cliente()` se definió con `SECURITY DEFINER` y `SET search_path = pg_catalog, public`:
- **`SECURITY DEFINER`** permite que el disparador inserte registros en `auditoria.cambios_clientes` en nombre de su propietario (`postgres`), manteniendo bloqueado el acceso directo de lectura o escritura para `app_ventas`.
- **`session_user` vs `current_user`:** Dentro de una función `SECURITY DEFINER`, `current_user` devuelve el propietario (`postgres`), mientras que `session_user` conserva la identidad real del rol autenticado (`app_ventas`).
- **Incidente auditado:** Al ejecutarse el cambio de RFC de María García (`id = 3`), el evento `id_evento = 1` permitió extraer campo por campo con `jsonb_each()` que `app_ventas` modificó `rfc` de `'GAMA780912XYZ'` a `'GAMA780912ZZZ'` el `2026-10-25 22:50:52.903439+00` desde `127.0.0.1`.

---

## 5. Limitaciones identificadas
- **Lecturas no registradas:** Ni `log_statement = 'mod'` ni los disparadores `AFTER INSERT/UPDATE/DELETE` detectan sentencias `SELECT`. Se mitigó en la Parte C mediante `pgaudit` con auditoría de objeto sobre las columnas `rfc` y `telefono`.
- **Volumen y rendimiento:** Un `UPDATE` masivo sin `WHERE` produce una línea en la bitácora del servidor, pero dispara una inserción `JSONB` por cada fila afectada en `auditoria.cambios_clientes`.
- **Administrador con control total:** Un superusuario (`postgres`) puede deshabilitar el disparador (`ALTER TABLE ... DISABLE TRIGGER`), modificar la tabla de auditoría o bajar `log_statement` a `'none'`. Aunque la desactivación queda registrada en la bitácora mientras `ddl`/`mod` estén activos, la protección definitiva exige enviar bitácoras a un servidor externo independiente.

---

## 6. Riesgos de la bitácora
- **Exposición de secretos:** Sentencias como `CREATE ROLE ... PASSWORD '...'` escriben contraseñas en texto claro en la bitácora (Actividad 6). Por ello deben usarse metacomandos como `\password` y sanitizar (`<REDACTED>`) cualquier exportación.
- **Pérdida o destrucción:** Conservar la bitácora únicamente en el disco local del contenedor o servidor expone la evidencia a rotación, reinstalación o borrado malicioso.
- **Acceso indebido:** La vista `dba.bitacora` y la tabla `auditoria.cambios_clientes` contienen datos personales sensibles (RFC, teléfonos) y deben restringirse estrictamente a roles de DBA y auditoría.

---

## 7. Cronología, conclusión y preguntas de reflexión

Con la configuración final implementada (bitácora del servidor con `logging_collector = on`, `log_connections = on`, `log_line_prefix` completo y `log_statement = 'mod'`, combinada con el disparador `SECURITY DEFINER` en `auditoria.cambios_clientes` y reforzada con `pgaudit`), **sí es posible demostrar de manera fehaciente quién modificó un dato sensible, cuándo ocurrió, desde qué dirección IP y qué valor exacto tenía antes del cambio**, siempre que dicha configuración se encuentre activa antes del incidente.

### Respuestas a las preguntas de reflexión (Sección 29)

1. **¿Por qué la auditoría no puede configurarse después de un incidente para investigarlo?**  
   Porque la auditoría es un registro prospectivo de eventos en tiempo real; PostgreSQL no almacena el historial de transacciones pasadas ni valores anteriores de filas una vez confirmados (`COMMIT`), por lo que lo no registrado en su momento es irrecuperable.
2. **¿Por qué conviene que la bitácora la administre el propio servidor y no el mecanismo de despliegue?**  
   Porque `logging_collector = on` estandariza la ubicación, formato, rotación y consulta SQL (`pg_current_logfile()`, `pg_read_file()`) sin depender de systemd, Docker o el sistema operativo anfitrión, evitando que los logs se pierdan al recrear contenedores.
3. **¿Por qué el prefijo de línea es tan importante como el nivel de `log_statement`?**  
   Porque `log_statement` registra *qué* sentencia SQL se ejecutó, pero sin los marcadores del `log_line_prefix` (`%u`, `%d`, `%h`, `%a`, `%m`, `%p`) es imposible atribuir esa sentencia a un usuario, base de datos, origen de red o sesión específica.
4. **¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?**  
   Registrar la sentencia (`log_statement`) captura la instrucción SQL enviada (útil para saber la intención y parámetros), pero no revela qué filas fueron afectadas ni qué valores tenían antes. Registrar el cambio en el dato (disparador + `JSONB`) captura el estado exacto *antes* y *después* por cada fila modificada, permitiendo revertir cambios con certeza.
5. **¿Qué evidencia ofrece `pg_stat_activity` que no ofrece la bitácora, y viceversa?**  
   `pg_stat_activity` ofrece una fotografía en vivo del estado actual de cada backend (consultas activas en curso, esperas, inicio de sesión), pero desaparece en cuanto termina la conexión. La bitácora conserva la historia cronológica persistente de conexiones, errores y sentencias ya finalizadas.
6. **Si el administrador puede cambiar `log_statement` a `none` y desactivar el disparador, ¿quién audita al administrador?**  
   Un sistema externo de recolección centralizada de bitácoras (SIEM / syslog remoto en tiempo real con almacenamiento inmutable) gestionado por un equipo independiente de Seguridad de la Información, bajo el principio organizacional de segregación de funciones.
