# Actividad 1 — Revisar la configuración de registro por defecto

## Comandos ejecutados y resultados

```sql
SELECT name, setting, source FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
               'log_connections', 'log_disconnections', 'log_line_prefix',
               'log_statement', 'log_min_error_statement', 'log_timezone')
ORDER BY name;
```

Resultado obtenido:
- `log_connections`: `off` (`default`)
- `log_destination`: `stderr` (`configuration file`)
- `log_directory`: `log` (`default`)
- `log_disconnections`: `off` (`default`)
- `log_filename`: `postgresql-%Y-%m-%d_%H%M%S.log` (`default`)
- `logging_collector`: `on` (`configuration file`)
- `log_line_prefix`: `%m [%p] ` (`default`)
- `log_min_error_statement`: `error` (`default`)
- `log_statement`: `none` (`default`)
- `log_timezone`: `America/Chihuahua` (`configuration file`)

## Pregunta de preparación (Sección 6.4)
**¿Por qué una regla `trust` afecta lo que la bitácora puede demostrar sobre la identidad del usuario?**  
Porque `trust` permite que cualquier cliente que cumpla con la dirección de red se conecte indicando el nombre de cualquier rol sin presentar contraseña ni prueba criptográfica de identidad. Aunque la bitácora registre el nombre del usuario declarado, no garantiza que haya sido realmente ese actor.

## Respuestas a las preguntas de la Actividad 1
1. **Con esta configuración, ¿se registra quién se conecta?**  
   No. `log_connections` está en `off`, por lo que los inicios de sesión exitosos no generan registro alguno.
2. **¿Se registran las sentencias UPDATE?**  
   No. `log_statement` tiene el valor `none`, así que ninguna sentencia SQL exitosa se escribe en la bitácora.
3. **¿La línea de bitácora incluye el usuario o la dirección IP del cliente?**  
   No. El prefijo `log_line_prefix = '%m [%p] '` solo registra la marca de tiempo con milisegundos (`%m`) y el identificador de proceso (`%p`). Carece de `%u` (usuario) y `%h` (host/IP).
4. **¿En qué zona horaria se registran los eventos? ¿Por qué importa al reconstruir una cronología?**  
   Se registran en `Etc/UTC`. Importa porque permite correlacionar los eventos de la base de datos con registros de servidores web, firewalls y sistemas operativos que operan en distintas zonas horarias o con horario de verano, evitando desfases temporales al armar la línea de tiempo forense.
5. **Con `logging_collector = off`, ¿quién decide dónde termina la bitácora: PostgreSQL o el mecanismo con que se desplegó el servidor?**  
   El mecanismo de despliegue (systemd, el gestor de servicios del sistema operativo o el runtime de contenedores), ya que PostgreSQL simplemente envía los mensajes a `stderr`.
