import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';

import '../domain/project.dart';
import 'project_providers.dart';

/// Lista de proyectos del usuario, cargada desde el repositorio.
///
/// Si la carga falla, el [AsyncError] transporta un [Failure] con un mensaje
/// apto para mostrar en pantalla.
class ProjectsController extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final repository = ref.watch(projectRepositoryProvider);
    var result = await repository.list();

    // Al arrancar, el token puede estar refrescándose: si el primer intento
    // falla por sesión/permiso, reintenta una vez antes de mostrar el error.
    if (result case Err(:final failure)) {
      final message = failure.message.toLowerCase();
      final transient =
          message.contains('permiso') ||
          message.contains('sesión') ||
          message.contains('session') ||
          message.contains('token') ||
          message.contains('jwt');
      if (transient) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        result = await repository.list();
      }
    }

    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Crea un proyecto y recarga la lista si tuvo éxito.
  ///
  /// Devuelve el [Result] para que la UI decida si muestra un aviso.
  Future<Result<void>> create({required String name}) async {
    final result = await ref
        .read(projectRepositoryProvider)
        .create(name: name);

    if (result is Ok) {
      ref.invalidateSelf();
    }

    return switch (result) {
      Ok() => const Ok(null),
      Err(:final failure) => Err(failure),
    };
  }

  /// Elimina un proyecto y recarga la lista si tuvo éxito.
  Future<Result<void>> delete(String projectId) async {
    final result = await ref.read(projectRepositoryProvider).delete(projectId);

    if (result is Ok) {
      ref.invalidateSelf();
    }

    return switch (result) {
      Ok() => const Ok(null),
      Err(:final failure) => Err(failure),
    };
  }

  /// Vuelve a cargar la lista (botón "Reintentar").
  void reload() => ref.invalidateSelf();
}

/// Controlador de la lista de proyectos.
final projectsControllerProvider =
    AsyncNotifierProvider<ProjectsController, List<Project>>(
      ProjectsController.new,
    );
