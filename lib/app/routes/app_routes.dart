class AppRoutes {
  static const dashboard = '/dashboard';
  static const users = '/users';
  static const administrators = '/administrators';
  static const accounts = '/accounts';
  static const condominiums = '/condominiums';
  static const blocks = '/blocks';
  static const apartments = '/apartments';
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
}
