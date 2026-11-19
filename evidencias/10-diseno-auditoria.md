# Actividad 10 — Diseñar y crear el registro de auditoría

## Diseño de la tabla `auditoria.cambios_clientes`

| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
| :--- | :--- | :--- | :--- |
| `id_evento` | `BIGSERIAL` | Identificador secuencial único del evento | **No** (`PRIMARY KEY`), garantiza orden e identificación unívoca. |
| `momento` | `TIMESTAMPTZ` | ¿Cuándo ocurrió el cambio? | **No**, todo registro de auditoría requiere marca temporal exacta. |
| `usuario_sesion` | `TEXT` | ¿Quién hizo el cambio? (rol autenticado) | **No**, identifica al responsable de la sesión. |
| `usuario_efectivo` | `TEXT` | ¿Con qué privilegios efectivos se ejecutó? | **No**, permite verificar la ejecución bajo `SECURITY DEFINER`. |
| `aplicacion` | `TEXT` | ¿Desde qué aplicación se conectó? | **Sí**, si el cliente no envía `application_name` puede ser vacío o nulo. |
| `ip_cliente` | `INET` | ¿Desde qué equipo/IP se conectó? | **Sí**, las conexiones por socket Unix local devuelven `NULL` en `inet_client_addr()`. |
| `operacion` | `TEXT` | ¿Qué acción se realizó (`INSERT`, `UPDATE`, `DELETE`)? | **No**, define la naturaleza de la modificación. |
| `id_cliente` | `BIGINT` | ¿Qué registro de cliente fue afectado? | **Sí** (o `NOT NULL` según diseño), facilita búsquedas rápidas por llave primaria del cliente. |
| `valores_antes` | `JSONB` | ¿Qué valor tenía el dato antes del cambio? | **Sí**, en operaciones `INSERT` no existe un registro previo. |
| `valores_despues` | `JSONB` | ¿Qué valor quedó después del cambio? | **Sí**, en operaciones `DELETE` no existe un registro posterior. |

## Respuestas a las preguntas
1. **¿Por qué `momento` usa `TIMESTAMPTZ` y no `TIMESTAMP`?**  
   Porque `TIMESTAMPTZ` almacena el instante exacto normalizado a UTC y lo presenta según la zona horaria de la sesión, evitando ambigüedades cuando servidores o clientes operan en distintas zonas horarias o sufren cambios de horario de verano.
2. **¿Por qué se guarda el registro completo en `JSONB` y no solo la columna que cambió?**  
   Porque el formato `JSONB` desacopla la tabla de auditoría del esquema de `clientes`: si en el futuro se agregan, eliminan o renombran columnas en `clientes` (como ocurrió al agregar `segmento`), la tabla de auditoría sigue funcionando sin fallos de esquema y conserva una fotografía íntegra de toda la fila.
3. **La tabla de auditoría también contendrá RFC. ¿Qué implica eso para su clasificación y su control de acceso?**  
   Implica que la tabla de auditoría hereda el mismo nivel de clasificación confidencial/datos personales sensibles que la tabla `clientes`. Por tanto, debe residir en un esquema separado (`auditoria`), sin acceso para `PUBLIC`, ni siquiera con permiso de lectura para roles operativos como `app_ventas` o `soporte_ana`.
