# Actividad 17 — Reconstruir la cronología y responder a Dirección 

## Cronología de eventos reconstruida

| # | Fecha y hora (UTC) | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente (línea o `id_evento`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | *Sin marca temporal* | `app_ventas` | `127.0.0.1` | Datos | Cambio inicial de `rfc` a `'GAMA780912XXX'` en `id=3` (Actividad 3) | Sí | **Hueco de evidencia** (bitácora apagada) |
| 2 | `2026-10-25 22:49:50.539` | `postgres` (PID 1) | `[local]` | Configuración | Activación de `log_connections`, `log_disconnections`, `log_line_prefix` y `log_statement='ddl'` | Sí | `bitacora-lab01.log` líneas 7–10 |
| 3 | `2026-10-25 22:50:00.334` | `app_ventas` | `127.0.0.1` | Acceso | Intento de conexión rechazado por contraseña incorrecta | No | `bitacora-lab01.log` líneas 14–15 |
| 4 | `2026-10-25 22:50:00.462` | `usuario_inexistente` | `127.0.0.1` | Acceso | Intento de conexión rechazado porque el rol no existe | No | `bitacora-lab01.log` líneas 17–18 |
| 5 | `2026-10-25 22:50:00.566` | `app_ventas` | `127.0.0.1` | Acceso | Conexión exitosa (`app=app-ventas-web`) y posterior desconexión | Sí | `bitacora-lab01.log` líneas 20–22 |
| 6 | `2026-10-25 22:50:09.341` | `postgres` | `[local]` | Privilegio | `REVOKE UPDATE ON clientes FROM soporte_ana` y `GRANT UPDATE ... TO app_ventas` | Sí | `bitacora-lab01.log` líneas 23–24 |
| 7 | `2026-10-25 22:50:09.372` | `postgres` | `[local]` | Estructura | `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)` | Sí | `bitacora-lab01.log` línea 25 |
| 8 | `2026-10-25 22:50:20.601` | `app_ventas` | `127.0.0.1` | Datos | Actualización de `telefono` a `'6679990000'` en `id=3` (`log_statement='mod'`) | Sí | `bitacora-lab01.log` línea 30 |
| 9 | `2026-10-25 22:50:24.112` | `soporte_ana` | `127.0.0.1` | Error | Intento rechazado de `DELETE FROM clientes WHERE id = 5` (`permission denied`) | No | `bitacora-lab01.log` líneas 31–32 |
| 10 | `2026-10-25 22:50:52.903` | `app_ventas` | `127.0.0.1` | Datos | Cambio de `rfc` de `'GAMA780912XYZ'` a `'GAMA780912ZZZ'` en `id=3` | Sí | `auditoria.cambios_clientes` (`id_evento = 1`) |
| 11 | `2026-10-25 22:51:12.805` | `postgres` | `[local]` | Estructura / Datos | Desactivación temporal de `trg_auditoria_clientes` y `UPDATE` de `rfc` a `'GAMA780912GHI'` en `id=3` | Sí | `bitacora-lab01.log` líneas 39–41 |

## Respuestas a las preguntas de Dirección (Sección 5)

1. **¿Quién cambió el RFC la primera vez (Actividad 3)? ¿Y en las Actividades 7, 12 y 14?**  
   - **Actividad 3 (primer cambio):** **No hay evidencia** en la bitácora ni en la tabla de auditoría, porque en ese momento `log_statement` estaba en `'none'`, `log_connections` en `'off'` y aún no existía el disparador de auditoría.  
   - **Actividad 7 (segundo cambio de RFC a `'GAMA780912XYZ'`):** **No hay evidencia de la sentencia `UPDATE`**, ya que `log_statement` estaba configurado en `'ddl'`; solo consta en bitácora la conexión y desconexión de `app_ventas` desde `127.0.0.1` con `application_name=app-ventas-web`, sin poder vincularla probatoriamente al `UPDATE`.  
   - **Actividad 12 (tercer cambio de RFC a `'GAMA780912ZZZ'`):** El rol **`app_ventas`** desde la IP **`127.0.0.1`** usando la aplicación **`app-ventas-web`** a las `2026-10-25 22:50:52.903439+00` (demostrado en `auditoria.cambios_clientes`, `id_evento = 1`).  
   - **Actividad 14 (cuarto cambio de RFC a `'GAMA780912GHI'`):** El administrador **`postgres`** desde conexión local **`[local]`** usando **`psql`** a las `2026-10-25 22:51:12.805 UTC`, tras deshabilitar temporalmente el disparador de auditoría (demostrado en `bitacora-lab01.log`, líneas 39–41).

2. **¿Quién cambió el teléfono?**  
   El rol **`app_ventas`** desde la IP **`127.0.0.1`** con la aplicación **`app-ventas-web`** el `2026-10-25 22:50:20.601 UTC`, mediante la sentencia `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` (`bitacora-lab01.log`, línea 30). *(Nota: La bitácora prueba quién ejecutó la sentencia y el nuevo valor, pero no el valor anterior del teléfono porque el disparador aún no estaba creado).*

3. **¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?**  
   **Sí.** En `bitacora-lab01.log` (líneas 14–18) constan dos intentos fallidos ocurridos el `2026-10-25 22:50:00 UTC` desde la dirección **`127.0.0.1`**:
   - Usuario **`app_ventas`** (fallo de autenticación por contraseña incorrecta).  
   - Usuario **`usuario_inexistente`** (fallo de autenticación porque el rol no existe en el servidor).

4. **¿Qué valor tenía el RFC antes de cada cambio?**  
   - **Antes del cambio de la Actividad 3:** **No hay evidencia** registrada en bitácora ni en auditoría de datos.  
   - **Antes del cambio de la Actividad 7:** **No hay evidencia** registrada en bitácora ni en auditoría de datos.  
   - **Antes del cambio de la Actividad 12:** Tenía el valor **`GAMA780912XYZ`** (registrado en `valores_antes` del evento `id_evento = 1` de `auditoria.cambios_clientes`).  
   - **Antes del cambio de la Actividad 14:** **No hay evidencia directa en el registro del evento** porque el disparador fue desactivado antes del `UPDATE`; sin embargo, por correlación con el último estado registrado en `auditoria.cambios_clientes` (`id_evento = 1`), su valor previo inmediato era **`GAMA780912ZZZ`**.

## Nota sobre exportación e integridad (Actividad 16)
La bitácora vigente fue exportada limpiando el secreto expuesto en la Actividad 6 (`Temporal_Practica_2026` → `<REDACTED>`) hacia `evidencias/bitacora-lab01.log` y se calculó su resumen criptográfico SHA-256 en `evidencias/bitacora-lab01.sha256`.

### Respuestas a las preguntas de la Actividad 16
1. **Un resumen SHA-256 ¿impide que alguien modifique la bitácora? ¿Qué permite demostrar?**  
   No impide físicamente la modificación del archivo, pero permite **detectar cualquier alteración posterior** (incluso de un solo bit) y demostrar la integridad y autenticidad del archivo exportado comparando el hash recalculado contra el hash original custodiado.
2. **¿Dónde debería guardarse el hash para que sea útil como control de integridad?**  
   En un medio o sistema independiente y protegido contra escritura/alteración por parte del administrador de la base de datos (por ejemplo, un servidor SIEM externo, almacenamiento WORM/inmutable o un repositorio con firma criptográfica y control de versiones auditado).
3. **La guía NIST SP 800-92 trata la conservación y protección de bitácoras. ¿Qué riesgos tiene conservar la bitácora solo en el servidor que la produce?**  
   Riesgo de **pérdida total de evidencia** ante fallos de hardware, reinstalación o destrucción del contenedor/VM, rotación automática que sobrescriba archivos antiguos, y **riesgo de manipulación o borrado** por parte de un atacante o administrador comprometido que obtenga control sobre el servidor.
4. **Propón durante cuánto tiempo conservarías esta bitácora y justifica tu criterio.**  
   Se propone conservar las bitácoras operativas en línea durante al menos **90 días** para respuesta rápida ante incidentes, y archivarlas en almacenamiento inmutable frío por un mínimo de **1 a 5 años** (dependiendo de obligaciones fiscales/mercantiles sobre datos de facturación de clientes en México, como el Código Fiscal de la Federación, y políticas internas de cumplimiento).
