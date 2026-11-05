import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class CepAddressResult {
  final String cep;
  final String street;
  final String complement;
  final String neighborhood;
  final String city;
  final String uf;

  const CepAddressResult({
    required this.cep,
    required this.street,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.uf,
  });

  factory CepAddressResult.fromViaCepMap(Map<String, dynamic> map) {
    final rawCep = (map['cep'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
    final formattedCep = rawCep.length == 8
        ? '${rawCep.substring(0, 5)}-${rawCep.substring(5)}'
        : (map['cep'] as String? ?? '').trim();

    return CepAddressResult(
      cep: formattedCep,
      street: (map['logradouro'] as String? ?? '').trim(),
      complement: (map['complemento'] as String? ?? '').trim(),
      neighborhood: (map['bairro'] as String? ?? '').trim(),
      city: (map['localidade'] as String? ?? '').trim(),
      uf: (map['uf'] as String? ?? '').trim().toUpperCase(),
    );
  }
}

class CepLookupException implements Exception {
  final String message;

  const CepLookupException(this.message);

  @override
  String toString() => message;
}

class CepDataSource {
  final http.Client _client;

  CepDataSource({http.Client? client}) : _client = client ?? http.Client();

  /// Consulta o endereço correspondente ao [rawCep] (8 dígitos) na API ViaCEP.
  /// Retorna `null` quando o CEP não existe na base.
  Future<CepAddressResult?> fetchAddressByCep(String rawCep) async {
    final digits = rawCep.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 8) {
      throw const CepLookupException('Informe um CEP válido com 8 dígitos.');
    }

    final uri = Uri.parse('https://viacep.com.br/ws/$digits/json/');

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 6));
    } on TimeoutException {
      throw const CepLookupException(
        'A consulta do CEP demorou muito. Você pode preencher o endereço manualmente.',
      );
    } catch (_) {
      throw const CepLookupException(
        'Não foi possível consultar o CEP no momento. Preencha o endereço manualmente.',
      );
    }

    if (response.statusCode == 400) {
      throw const CepLookupException('Formato de CEP inválido.');
    }

    if (response.statusCode != 200) {
      throw const CepLookupException(
        'Serviço de CEP indisponível no momento. Preencha o endereço manualmente.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const CepLookupException(
        'Resposta inválida ao consultar o CEP. Preencha o endereço manualmente.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const CepLookupException(
        'Resposta inesperada ao consultar o CEP. Preencha o endereço manualmente.',
      );
    }

    final erro = decoded['erro'];
    if (erro == true || erro == 'true') {
      return null;
    }

    return CepAddressResult.fromViaCepMap(decoded);
  }
}
