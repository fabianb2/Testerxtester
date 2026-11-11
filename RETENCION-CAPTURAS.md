# Borrado de capturas a las 48 horas

1. Ejecutar `supabase/08-evidence-retention.sql` después de la consulta 07.
2. En GitHub: Configuración → Secretos y variables → Actions → Nuevo secreto del repositorio.
   - `SUPABASE_URL`: dirección del proyecto Supabase.
   - `SUPABASE_SERVICE_ROLE_KEY`: clave service_role (solo en GitHub Actions, nunca en Vercel con prefijo VITE ni en React).
3. Abrir Actions → Eliminar capturas con más de 48 horas → Ejecutar flujo. Comprobar que finalice correctamente.

El flujo se ejecuta cada hora. El borrado ocurre en la primera ejecución exitosa después de cumplir 48 horas; GitHub puede retrasar ejecuciones. Incluye capturas reemplazadas y huérfanas de apps borradas. Los iconos de apps no se eliminan. El texto del feedback permanece.

Se usa Storage API para borrar el archivo físico. Las referencias se limpian solo cuando el archivo ya no existe. Si una ejecución falla, se reintenta en el siguiente horario. Para cambios del proyecto SQL no hay conexión de Supabase disponible en este chat: la consulta y los secretos necesitan configuración del propietario.

La tarea se guarda en el repositorio y puede desactivarse desde Actions. GitHub puede desactivar tareas programadas en repositorios públicos sin actividad durante 60 días: revisar ese estado si el grupo deja de usar el repositorio.
