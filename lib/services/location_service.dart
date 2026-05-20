import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/governorate_model.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  List<GovernorateModel>? _cached;

  Future<List<GovernorateModel>> loadGovernorates() async {
    if (_cached != null) return _cached!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/governorates.json');
      final List<dynamic> list = json.decode(jsonStr);
      _cached = list.map((e) => GovernorateModel.fromJson(e as Map<String, dynamic>)).toList();
      return _cached!;
    } catch (_) {
      return [];
    }
  }
}
