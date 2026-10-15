import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_history.dart';
import '../models/service_component.dart';
import '../models/vehicle_info.dart';

class ServiceRepository {
  static const String storageKey = 'servisku_service_history_v1';
  final SharedPreferences? prefs;

  ServiceRepository({this.prefs});

  Future<SharedPreferences> _getPrefs() async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.reload();
    return p;
  }

  // Read (Read from local persistence)
  Future<List<ServiceHistory>> fetchServiceHistory() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(storageKey);
    
    if (jsonString == null || jsonString.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final list = decoded
          .map((item) => ServiceHistory.fromMap(item as Map<String, dynamic>))
          .toList();
      // Urutkan dari riwayat terbaru (createdAt descending)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      // Jika terjadi kegagalan parsing, kembalikan list kosong
      return [];
    }
  }

  // Create (Save new record to local persistence)
  Future<void> addServiceHistory(ServiceHistory service) async {
    final prefs = await _getPrefs();
    final currentList = await fetchServiceHistory();
    // Tambahkan di awal list atau replace jika ID sudah ada
    currentList.removeWhere((item) => item.id == service.id);
    currentList.insert(0, service);
    await _saveList(prefs, currentList);
  }

  // Update (Update existing record in local persistence)
  Future<void> updateServiceHistory(ServiceHistory service) async {
    final prefs = await _getPrefs();
    final currentList = await fetchServiceHistory();
    final index = currentList.indexWhere((item) => item.id == service.id);
    if (index != -1) {
      currentList[index] = service;
      await _saveList(prefs, currentList);
    }
  }

  // Delete (Remove record from local persistence)
  Future<void> deleteServiceHistory(String id) async {
    final prefs = await _getPrefs();
    final currentList = await fetchServiceHistory();
    currentList.removeWhere((item) => item.id == id);
    await _saveList(prefs, currentList);
  }

  // Helper untuk menyimpan list ke SharedPreferences
  Future<void> _saveList(SharedPreferences prefs, List<ServiceHistory> list) async {
    final jsonList = list.map((item) => item.toMap()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(storageKey, jsonString);
  }

  static const String vehicleStorageKey = 'servisku_vehicle_info_v1';

  // Read Vehicle Info
  Future<VehicleInfo> fetchVehicleInfo() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(vehicleStorageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return VehicleInfo.defaultVehicle;
    }
    try {
      return VehicleInfo.fromJson(jsonString);
    } catch (_) {
      return VehicleInfo.defaultVehicle;
    }
  }

  // Save Vehicle Info
  Future<void> saveVehicleInfo(VehicleInfo info) async {
    final prefs = await _getPrefs();
    await prefs.setString(vehicleStorageKey, info.toJson());
  }

  static const String componentsStorageKey = 'servisku_service_components_v1';

  // Read Components
  Future<List<ServiceComponent>> fetchComponents() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString(componentsStorageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return List<ServiceComponent>.from(ServiceComponent.defaultPresets);
    }
    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => ServiceComponent.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List<ServiceComponent>.from(ServiceComponent.defaultPresets);
    }
  }

  // Add Component
  Future<void> addComponent(ServiceComponent component) async {
    final prefs = await _getPrefs();
    final currentList = await fetchComponents();
    currentList.removeWhere((item) => item.id == component.id);
    currentList.add(component);
    final jsonList = currentList.map((item) => item.toMap()).toList();
    await prefs.setString(componentsStorageKey, json.encode(jsonList));
  }

  // Update Component
  Future<void> updateComponent(ServiceComponent component) async {
    final prefs = await _getPrefs();
    final currentList = await fetchComponents();
    final index = currentList.indexWhere((item) => item.id == component.id);
    if (index != -1) {
      currentList[index] = component;
      final jsonList = currentList.map((item) => item.toMap()).toList();
      await prefs.setString(componentsStorageKey, json.encode(jsonList));
    }
  }

  // Delete Component
  Future<void> deleteComponent(String id) async {
    final prefs = await _getPrefs();
    final currentList = await fetchComponents();
    currentList.removeWhere((item) => item.id == id);
    final jsonList = currentList.map((item) => item.toMap()).toList();
    await prefs.setString(componentsStorageKey, json.encode(jsonList));
  }

  // Helper untuk reset/hapus semua data lokal
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(storageKey);
    await prefs.remove(vehicleStorageKey);
    await prefs.remove(componentsStorageKey);
  }
}
