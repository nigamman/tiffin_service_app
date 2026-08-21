import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class MenuModel {
  final String id;
  final List<String> items;
  final double price;
  final String imageUrl;

  MenuModel({
    required this.id,
    required this.items,
    required this.price,
    required this.imageUrl,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map) {
    return MenuModel(
      id: map['_id'] ?? map['id'] ?? '',
      items: List<String>.from(map['items'] ?? []),
      price: (map['price'] as num?)?.toDouble() ?? 80.0,
      imageUrl: map['imageUrl'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}

class MenuRepository {
  final ApiClient _apiClient = ApiClient();

  // Storage for mock menu edits in memory during local execution
  static MenuModel? _mockMenu;

  Future<MenuModel> getActiveMenu() async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Seed default mock menu if none is edited yet
      _mockMenu ??= MenuModel(
        id: 'mock_menu_today_101',
        items: ['Dal Fry', 'Seasonal Sabzi', '4 Roti', 'Steamed Rice', 'Salad', 'Pickle'],
        price: 80.0,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      );
      
      return _mockMenu!;
    } else {
      final response = await _apiClient.get('/menu');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MenuModel.fromMap(data['menu']);
      } else {
        throw Exception('Failed to fetch today\'s menu');
      }
    }
  }

  Future<MenuModel> updateActiveMenu(List<String> items, double price) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 600));
      _mockMenu = MenuModel(
        id: 'mock_menu_today_101',
        items: items,
        price: price,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      );
      return _mockMenu!;
    } else {
      final response = await _apiClient.post('/menu', {
        'items': items,
        'price': price,
        'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MenuModel.fromMap(data['menu']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update today\'s menu');
      }
    }
  }
}
