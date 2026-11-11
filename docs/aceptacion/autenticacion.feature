# language: es
# Contrato de aceptación de autenticación y aislamiento multi-tenant.
# Depende del esquema Supabase (profiles, projects, project_screens) y de RLS.
Característica: Autenticación y aislamiento entre inquilinos
  Como usuario registrado
  Quiero autenticarme y acceder solo a mis proyectos
  Para que mis datos no sean visibles para otros usuarios

  Escenario: Inicio de sesión con credenciales válidas
    Dado un usuario registrado
    Cuando introduce su correo y contraseña válidos
    Entonces llega a la pantalla de proyectos
    Y su sesión queda persistida en almacenamiento seguro

  Escenario: Inicio de sesión con credenciales inválidas
    Dado un usuario no registrado
    Cuando intenta iniciar sesión
    Entonces ve el mensaje "Credenciales inválidas"
    Y no se crea ninguna sesión

  Escenario: Registro con un correo nuevo
    Dado que no tengo cuenta
    Cuando me registro con un correo y una contraseña de 8 caracteres o más
    Entonces se crea la cuenta
    Y veo el aviso de revisar mi correo para confirmarla

  Escenario: Registro con contraseñas que no coinciden
    Cuando envío el formulario con dos contraseñas distintas
    Entonces veo "Las contraseñas no coinciden."
    Y no se llama al servidor

  Escenario: Registro con un correo ya existente
    Dado un correo ya registrado
    Cuando intento registrarme de nuevo con ese correo
    Entonces veo "Ese correo ya está registrado."

  Escenario: Recuperación de contraseña
    Dado que olvidé mi contraseña
    Cuando pido un enlace de recuperación
    Entonces veo un mensaje neutral: "Si el correo está registrado..."
    Y el mensaje es idéntico exista o no la cuenta

  Escenario: Abrir el enlace de recuperación
    Dado que abrí el enlace del correo
    Entonces la app me pide una nueva contraseña
    Cuando guardo una contraseña válida dos veces
    Entonces entro a mis proyectos con la contraseña nueva

  Escenario: Contraseñas distintas al restablecer
    Cuando confirmo con una contraseña distinta
    Entonces veo "Las contraseñas no coinciden."
    Y no se llama al servidor

  Escenario: Acceso a una pantalla protegida sin sesión
    Dado que no hay sesión activa
    Cuando navega directamente a /projects
    Entonces es redirigido a /login

  Escenario: Un usuario no ve los proyectos de otro
    Dado el usuario A autenticado
    Y un proyecto perteneciente al usuario B
    Cuando el usuario A consulta la tabla projects
    Entonces recibe cero filas
    Y la base de datos aplica la política RLS owner_id = auth.uid()

  Escenario: No se puede modificar un proyecto ajeno
    Dado el usuario A autenticado
    Y un proyecto perteneciente al usuario B
    Cuando el usuario A intenta actualizar ese proyecto
    Entonces la operación falla
    Y el dato del usuario B no se modifica

  Escenario: El cliente no puede asumir privilegios
    Dado el binario web publicado
    Entonces solo contiene la clave anon
    Y no contiene la service_role
