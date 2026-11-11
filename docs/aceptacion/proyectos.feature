# language: es
# Contrato del CRUD de proyectos contra tenant_app.projects (RLS).
Característica: Gestión de proyectos
  Como usuario autenticado
  Quiero crear y ver mis proyectos
  Para empezar a diseñar pantallas dentro de ellos

  Escenario: Sin proyectos
    Dado que acabo de crear mi cuenta
    Cuando abro la pantalla de proyectos
    Entonces veo "Aún no tienes proyectos"
    Y puedo crear el primero

  Escenario: Crear un proyecto
    Cuando creo un proyecto llamado "Mi app"
    Entonces aparece en mi lista
    Y queda asociado a mi usuario (owner_id = auth.uid())

  Escenario: Nombre inválido
    Cuando intento crear un proyecto con un nombre vacío o de más de 120 caracteres
    Entonces veo un mensaje de validación
    Y no se crea ninguna fila

  Escenario: Solo veo mis proyectos
    Dado que existe un proyecto de otro usuario
    Cuando abro mi pantalla de proyectos
    Entonces no aparece ese proyecto
    Y la base devuelve solo las filas donde owner_id = auth.uid()

  Escenario: Error de red
    Cuando falla la carga de proyectos
    Entonces veo el mensaje de error
    Y puedo reintentar
