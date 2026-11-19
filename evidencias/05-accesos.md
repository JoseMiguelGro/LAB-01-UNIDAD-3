# Actividad 5 — Accesos exitosos y fallidos

## Comandos ejecutados y resultados

```bash
psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial" -c "SELECT 1"
# FATAL: password authentication failed for user "app_ventas"

psql "postgresql://usuario_inexistente:<REDACTED>@127.0.0.1/comercial" -c "SELECT 1"
# FATAL: password authentication failed for user "usuario_inexistente"

psql "postgresql://app_ventas:<REDACTED>@127.0.0.1/comercial?application_name=app-ventas-web" -c "SELECT count(*) FROM clientes"
# count: 5
```

## Respuestas a las preguntas
1. **La bitácora registra el usuario `app_ventas` en el intento fallido. ¿Eso prueba que la aplicación de ventas intentó entrar? ¿Qué prueba realmente?**  
   No prueba que haya sido la aplicación legítima. Prueba únicamente que desde la dirección IP `127.0.0.1` un cliente solicitó autenticarse declarando el nombre de rol `app_ventas` y proporcionó credenciales inválidas.
2. **¿Qué información adicional registra PostgreSQL cuando el rol no existe? ¿Por qué aparece en la bitácora y no en el mensaje que recibe el cliente?**  
   Registra la línea `DETAIL: Role "usuario_inexistente" does not exist.`. Se omite en el mensaje al cliente por seguridad (prevención de enumeración de usuarios): así un atacante externo no puede distinguir entre un usuario válido con contraseña errónea y un usuario inexistente, mientras que el administrador sí tiene el detalle completo para diagnosticar.
3. **¿Por qué `app=[unknown]` en el intento fallido, pero `app=app-ventas-web` en la desconexión?**  
   Porque durante el *handshake* inicial de autenticación (antes de completar el paquete de inicio autorizado), el parámetro `application_name` aún no se ha procesado o establecido en el proceso backend. En el intento fallido la sesión aborta en esa fase; en el exitoso, tras `connection authorized`, el backend asigna `application_name` y lo muestra en las líneas posteriores (como la desconexión).
4. **¿Qué patrón de varias líneas te haría sospechar de un ataque de fuerza bruta? Escribe la consulta que contaría los intentos fallidos por usuario.**  
   Múltiples líneas consecutivas con `FATAL: password authentication failed for user ...` procedentes de la misma IP (`client=...`) en un intervalo corto de segundos, probando distintas contraseñas contra un mismo rol o barridos de distintos nombres de usuario (`Role "..." does not exist`).

   Consulta SQL:
   ```sql
   SELECT substring(linea FROM 'user=([^ ]+)') AS usuario,
          count(*) AS intentos_fallidos
   FROM dba.bitacora
   WHERE linea LIKE '%FATAL:  password authentication failed%'
   GROUP BY usuario
   ORDER BY intentos_fallidos DESC;
   ```
