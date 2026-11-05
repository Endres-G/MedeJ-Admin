class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';

  // Gestão (rotas principais do menu lateral)
  static const administrators = '/administrators';
  static const condominiums = '/condominiums';
  static const accounts = '/accounts';

  // Operação (rotas principais do menu lateral)
  static const readings = '/readings';
  static const reports = '/reports';

  // Administradoras
  static const administratorDetails = '/administrators/:administratorId';
  static const newCondominium =
      '/administrators/:administratorId/condominiums/new';

  // Condomínios
  static const condominiumDetails = '/condominiums/:condominiumId';

  // Blocos
  static const condominiumBlocks = '/condominiums/:condominiumId/blocks';
  static const newBlock = '/condominiums/:condominiumId/blocks/new';
  static const blockDetails = '/condominiums/:condominiumId/blocks/:blockId';

  // Apartamentos
  static const condominiumApartments =
      '/condominiums/:condominiumId/apartments';
  static const newApartment = '/condominiums/:condominiumId/apartments/new';

  // Usuários / contas do condomínio
  static const condominiumUsers = '/condominiums/:condominiumId/users';
  static const newCondominiumUser = '/condominiums/:condominiumId/users/new';

  // Helpers de construção de URLs seguras
  static String administratorDetailsPath(String administratorId) {
    return '/administrators/$administratorId';
  }

  static String newCondominiumPath(String administratorId) {
    return '/administrators/$administratorId/condominiums/new';
  }

  static String condominiumDetailsPath(
    String condominiumId, {
    String? administratorId,
  }) {
    return _withQuery('/condominiums/$condominiumId', {
      if (administratorId != null && administratorId.isNotEmpty)
        'administratorId': administratorId,
    });
  }

  static String condominiumBlocksPath(
    String condominiumId, {
    String? administratorId,
  }) {
    return _withQuery('/condominiums/$condominiumId/blocks', {
      if (administratorId != null && administratorId.isNotEmpty)
        'administratorId': administratorId,
    });
  }

  static String newBlockPath(String condominiumId, {String? administratorId}) {
    return _withQuery('/condominiums/$condominiumId/blocks/new', {
      if (administratorId != null && administratorId.isNotEmpty)
        'administratorId': administratorId,
    });
  }

  static String blockDetailsPath(
    String condominiumId,
    String blockId, {
    String? administratorId,
  }) {
    return _withQuery('/condominiums/$condominiumId/blocks/$blockId', {
      if (administratorId != null && administratorId.isNotEmpty)
        'administratorId': administratorId,
    });
  }

  static String condominiumApartmentsPath(
    String condominiumId, {
    String? administratorId,
  }) {
    return _withQuery('/condominiums/$condominiumId/apartments', {
      if (administratorId != null && administratorId.isNotEmpty)
        'administratorId': administratorId,
    });
  }

  static String newApartmentPath(
    String condominiumId, {
    String? administratorId,
    String? blockId,
  }) {
    return _withQuery('/condominiums/$condominiumId/apartments/new', {
      if (administratorId != null && administratorId.isNotEmpty)
        'administratorId': administratorId,
      if (blockId != null && blockId.isNotEmpty) 'blockId': blockId,
    });
  }

  static String condominiumUsersPath(
    String condominiumId, {
    String? administratorId,
  }) {
    return _withQuery('/condominiums/$condominiumId/users', {
      if (administratorId != null && administratorId.isNotEmpty)
        'administratorId': administratorId,
    });
  }

  static String newCondominiumUserPath(
    String condominiumId, {
    String? administratorId,
  }) {
    return _withQuery('/condominiums/$condominiumId/users/new', {
      if (administratorId != null && administratorId.isNotEmpty)
        'administratorId': administratorId,
    });
  }

  static String _withQuery(String path, Map<String, String> queryParameters) {
    if (queryParameters.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: queryParameters).toString();
  }
}
