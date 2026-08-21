import '../../../core/services/firebase_service.dart';

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
      id: map['id'] ?? '',
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
  final FirebaseService _db = FirebaseService.instance;

  Future<MenuModel> getActiveMenu() async {
    // 1. Fetch menu documents where isActive == true
    final activeMenus = await _db.collectionGetWhere('menu', 'isActive', true);
    
    if (activeMenus.isNotEmpty) {
      return MenuModel.fromMap(activeMenus.first);
    }
    
    // Fallback menu seeding if collection becomes empty
    final fallbackMap = {
      'id': 'mock_menu_today_101',
      'items': ['Dal Fry', 'Seasonal Sabzi', '4 Roti', 'Steamed Rice', 'Salad', 'Pickle'],
      'price': 80.0,
      'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      'isActive': true,
      'date': DateTime.now().toIso8601String(),
    };
    await _db.docSet('menu', 'mock_menu_today_101', fallbackMap);
    return MenuModel.fromMap(fallbackMap);
  }

  Future<MenuModel> updateActiveMenu(List<String> items, double price) async {
    // Disable previous active menus
    final allMenus = await _db.collectionGet('menu');
    for (final m in allMenus) {
      if (m['isActive'] == true) {
        await _db.docUpdate('menu', m['id'], {'isActive': false});
      }
    }

    // Add a new active menu document to Firestore
    final newMenuMap = {
      'items': items,
      'price': price,
      'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      'isActive': true,
      'date': DateTime.now().toIso8601String(),
    };

    final createdDoc = await _db.docAdd('menu', newMenuMap);
    return MenuModel.fromMap(createdDoc);
  }
}
