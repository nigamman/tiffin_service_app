import '../../../core/services/firebase_service.dart';

class MenuModel {
  final String id;
  final List<String> items;
  final double price;
  final String imageUrl;
  final String slot;

  MenuModel({
    required this.id,
    required this.items,
    required this.price,
    required this.imageUrl,
    required this.slot,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map) {
    return MenuModel(
      id: map['id'] ?? '',
      items: List<String>.from(map['items'] ?? []),
      price: (map['price'] as num?)?.toDouble() ?? 80.0,
      imageUrl: map['imageUrl'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      slot: map['slot'] ?? 'lunch',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items,
      'price': price,
      'imageUrl': imageUrl,
      'slot': slot,
    };
  }
}

class MenuRepository {
  final FirebaseService _db = FirebaseService.instance;

  Future<MenuModel> getActiveMenu() async {
    // Kept for simple backwards compatibility, returns lunch
    final menus = await getActiveMenus();
    return menus.firstWhere((m) => m.slot == 'lunch', orElse: () => menus.first);
  }

  Future<List<MenuModel>> getActiveMenus() async {
    // 1. Fetch menu documents where isActive == true
    final activeMenus = await _db.collectionGetWhere('menu', 'isActive', true);
    
    if (activeMenus.isNotEmpty) {
      return activeMenus.map((m) => MenuModel.fromMap(m)).toList();
    }
    
    // Fallback menu seeding if collection becomes empty
    final fallbackLunch = {
      'id': 'mock_menu_today_101',
      'items': ['Dal Fry', 'Seasonal Sabzi', '4 Roti', 'Steamed Rice', 'Salad', 'Pickle'],
      'price': 80.0,
      'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      'isActive': true,
      'slot': 'lunch',
      'date': DateTime.now().toIso8601String(),
    };
    final fallbackDinner = {
      'id': 'mock_menu_dinner_101',
      'items': ['Paneer Butter Masala', 'Veg Jhalfrezi', '4 Roti', 'Steamed Rice', 'Salad', 'Rayta'],
      'price': 90.0,
      'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      'isActive': true,
      'slot': 'dinner',
      'date': DateTime.now().toIso8601String(),
    };
    await _db.docSet('menu', 'mock_menu_today_101', fallbackLunch);
    await _db.docSet('menu', 'mock_menu_dinner_101', fallbackDinner);
    return [MenuModel.fromMap(fallbackLunch), MenuModel.fromMap(fallbackDinner)];
  }

  Future<MenuModel> updateActiveMenu(List<String> items, double price, [String slot = 'lunch']) async {
    // Disable previous active menus for this specific slot
    final allMenus = await _db.collectionGet('menu');
    for (final m in allMenus) {
      if (m['isActive'] == true && (m['slot'] ?? 'lunch') == slot) {
        await _db.docUpdate('menu', m['id'], {'isActive': false});
      }
    }

    // Add a new active menu document to Firestore
    final newMenuMap = {
      'items': items,
      'price': price,
      'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      'isActive': true,
      'slot': slot,
      'date': DateTime.now().toIso8601String(),
    };

    final createdDoc = await _db.docAdd('menu', newMenuMap);
    return MenuModel.fromMap(createdDoc);
  }
}
