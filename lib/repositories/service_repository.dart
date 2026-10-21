import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_history.dart';
import '../models/service_component.dart';
import '../models/vehicle_info.dart';
import '../services/api_service.dart';

class ServiceRepository {
  static const String storageKey = 'servisku_service_history_v1';
  final SharedPreferences? prefs;
  final ApiService? apiService;

  ServiceRepository({this.prefs, this.apiService});

  Future<SharedPreferences> _getPrefs() async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.reload();
    return p;
  }

  Future<List<ServiceHistory>> _fetchLocalList(SharedPreferences p) async {
    final jsonString = p.getString(storageKey);
    if (jsonString == null || jsonString.trim().isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
      final list = decoded
          .map((item) => ServiceHistory.fromMap(item as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  // Read: Loading dari Backend API (jika apiService tersedia) atau dari local persistence
  Future<List<ServiceHistory>> fetchServiceHistory() async {
    if (apiService != null) {
      final list = await apiService!.fetchServices();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (prefs != null) {
        await _saveList(prefs!, list);
      }
      return list;
    }

    final p = await _getPrefs();
    return _fetchLocalList(p);
  }

  // Create: Penyimpanan data ke Backend & update storage lokal
  Future<void> addServiceHistory(ServiceHistory service) async {
    if (apiService != null) {
      await apiService!.createService(service);
      if (prefs != null) {
        final currentList = await _fetchLocalList(prefs!);
        currentList.removeWhere((item) => item.id == service.id);
        currentList.insert(0, service);
        await _saveList(prefs!, currentList);
      }
      return;
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    currentList.removeWhere((item) => item.id == service.id);
    currentList.insert(0, service);
    await _saveList(p, currentList);
  }

  // Update: Perbarui data di Backend & storage lokal
  Future<void> updateServiceHistory(ServiceHistory service) async {
    if (apiService != null) {
      await apiService!.updateService(service);
      if (prefs != null) {
        final currentList = await _fetchLocalList(prefs!);
        final index = currentList.indexWhere((item) => item.id == service.id);
        if (index != -1) {
          currentList[index] = service;
          await _saveList(prefs!, currentList);
        }
      }
      return;
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    final index = currentList.indexWhere((item) => item.id == service.id);
    if (index != -1) {
      currentList[index] = service;
      await _saveList(p, currentList);
    }
  }

  // Delete: Hapus data di Backend & storage lokal
  Future<void> deleteServiceHistory(String id) async {
    if (apiService != null) {
      await apiService!.deleteService(id);
      if (prefs != null) {
        final currentList = await _fetchLocalList(prefs!);
        currentList.removeWhere((item) => item.id == id);
        await _saveList(prefs!, currentList);
      }
      return;
    }

    final p = await _getPrefs();
    final currentList = await _fetchLocalList(p);
    currentList.removeWhere((item) => item.id == id);
    await _saveList(p, currentList);
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
