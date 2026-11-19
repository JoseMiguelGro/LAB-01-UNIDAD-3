# Actividad 3 — El incidente sin bitácora  

## Comandos ejecutados y resultados

```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3"
# UPDATE 1
```

Consulta en sesión de administrador:
```sql
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%' OR linea LIKE '%app_ventas%';
-- (0 rows)
```

## Respuestas a las preguntas
1. **¿Puedes demostrar quién modificó el RFC?**  
   No. Aunque sabemos que `app_ventas` y `postgres` tienen privilegios `UPDATE` sobre `clientes`, no existe ningún registro de la conexión ni de la sentencia ejecutada.
2. **¿Puedes demostrar que el cambio no lo hizo `soporte_ana`?**  
   Podemos argumentar por control de acceso que `soporte_ana` solo posee privilegio `SELECT` sobre `clientes` (y no tiene atributos de superusuario), por lo que el motor rechazaría un `UPDATE` suyo; sin embargo, no hay evidencia positiva en bitácora de quién sí lo hizo ni de si alguien escaló privilegios temporalmente.
3. **Los privilegios de la Unidad II, ¿impidieron el cambio? ¿Debían impedirlo?**  
   No lo impidieron ni debían impedirlo, porque el rol `app_ventas` requiere legítimamente el permiso `UPDATE` sobre `clientes` para operar el negocio. El control de acceso previene acciones no autorizadas, pero no fiscaliza el uso legítimo o abusivo de permisos válidos.
4. **¿Qué tendría que haber estado configurado antes del incidente?**  
   El colector (`logging_collector = on`), el registro de conexiones (`log_connections = on`), un prefijo completo (`log_line_prefix` con `%u`, `%d`, `%a`, `%h`), `log_statement = 'mod'` para capturar sentencias de modificación, y un mecanismo de auditoría a nivel de dato (disparador) para conservar el valor anterior del RFC.
