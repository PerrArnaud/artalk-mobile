import 'package:flutter/material.dart';
import '../models/motw.dart';
import '../models/art_type.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

class MOTWProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<MOTW> _motwList = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  List<ArtType> _artTypes = [];
  int? _selectedArtTypeId;

  List<MOTW> get motwList => _motwList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  List<ArtType> get artTypes => _artTypes;
  int? get selectedArtTypeId => _selectedArtTypeId;

  Future<void> fetchArtTypes() async {
    try {
      final response = await _apiService.get(ApiConfig.artTypesUrl);
      final data = await _apiService.handleResponse(response);
      if (data['success'] == true && data['data'] != null) {
        _artTypes = (data['data'] as List<dynamic>)
            .map((json) => ArtType.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // ignore
    }
  }

  void setArtTypeFilter(int? artTypeId) {
    _selectedArtTypeId = artTypeId;
    fetchMOTWList(refresh: true);
  }

  Future<void> fetchMOTWList({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _currentPage = 1;
      _motwList.clear();
      _hasMore = true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var url = '${ApiConfig.motwUrl}?page=$_currentPage&limit=10';
      if (_selectedArtTypeId != null) {
        url += '&artTypeId=$_selectedArtTypeId';
      }
      final response = await _apiService.get(url);
      
      final data = await _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> motwData = data['data'] as List<dynamic>;
        final newMotws = motwData
            .map((json) => MOTW.fromJson(json as Map<String, dynamic>))
            .toList();
        
        if (refresh) {
          _motwList = newMotws;
        } else {
          _motwList.addAll(newMotws);
        }

        if (data['pagination'] != null) {
          final pagination = data['pagination'] as Map<String, dynamic>;
          _totalPages = pagination['pages'] as int? ?? 1;
          _hasMore = _currentPage < _totalPages;
        } else {
          _hasMore = false;
        }

        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MOTW?> fetchMOTWDetail(String slug) async {
    try {
      final response = await _apiService.get(ApiConfig.motwDetailUrl(slug));
      final data = await _apiService.handleResponse(response);
      
      if (data['success'] == true && data['data'] != null) {
        return MOTW.fromJson(data['data'] as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
