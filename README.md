# Tester × Tester

Web privada en React con Supabase. Proyecto independiente de Freddtech-Web.

## Inicio local

Requiere Node 20.19+ o 22.12+.

```powershell
npm install
npm run dev
```

Sin configuración muestra una demostración con datos ficticios en memoria. No guarda registros ni autentica usuarios. Al configurar Supabase desaparece el modo demo y se exige acceso.

## Conectar Supabase

1. Crea un proyecto en tu cuenta de Supabase.
2. Ejecuta `supabase/schema.sql` una sola vez en SQL Editor, sobre un proyecto nuevo.
3. En Authentication → Providers → Email, desactiva el registro de nuevos usuarios. Crea las cuentas del grupo desde Authentication → Users → Add user, con contraseña y correo confirmado. El acceso de esta primera versión es con correo y contraseña.
4. Copia el UUID de cada usuario y autorízalo desde SQL Editor:

```sql
insert into public.members(id,display_name,role)
values ('UUID_DEL_USUARIO','Nombre del integrante','member');
```

Para tu propia cuenta usa `admin` como rol. La pertenencia al grupo solo se gestiona desde el panel de Supabase, no desde el navegador.

5. Copia `.env.example` a `.env.local`. Completa la URL del proyecto y la clave **publishable** de Supabase. Nunca uses una clave secret ni service_role en la web.
6. Reinicia `npm run dev`.

## Desplegar en Vercel

Importa esta carpeta como proyecto Vite, con comando `npm run build` y directorio de salida `dist`. Configura `VITE_SUPABASE_URL` y `VITE_SUPABASE_PUBLISHABLE_KEY` en las variables del proyecto antes de construir. No hace falta dominio propio. La dirección puede abrirse públicamente, pero los registros exigen sesión y membresía autorizada mediante reglas de la base de datos.

## Comportamiento

- Cada aplicación tiene desarrollador, nombre y tres enlaces obligatorios: grupo, aceptación y app.
- Sus enlaces se muestran en ese mismo orden y se abren en otra pestaña.
- Cada miembro publica y edita sus apps; un administrador puede editar cualquiera.
- Cada persona confirma o retira su participación; no puede confirmar en nombre de otra. La clave compuesta impide duplicados.
- Los nombres de los participantes solo son visibles para miembros autorizados.
- El botón registra una declaración del usuario; no verifica instalaciones ni actividad en Google Play.
- Actualizar recarga los datos compartidos. Esta versión no utiliza suscripciones en tiempo real.
- Quitar un miembro desde la tabla `members` revoca su acceso y elimina sus apps y participaciones por cascada. Para retirar acceso conservando su contenido, habrá que incorporar un estado de membresía antes de hacerlo.

## Verificación pendiente de conexión

La compilación local valida el paquete frontend. Antes de invitar al grupo, ejecuta el esquema y prueba con dos cuentas y otra no autorizada: publicar y editar solo lo propio, confirmar sin duplicados y comprobar que la cuenta ajena al grupo no puede leer registros. Revisa en Supabase copias de seguridad y recuperación de contraseñas para el uso habitual.
