import 'package:flutter/material.dart';
import 'package:greennest/models/plant.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalQuantity {
    var total = 0;
    _items.forEach((key, item) {
      total += item.quantity;
    });
    return total;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.plant.price * item.quantity;
    });
    return total;
  }

  void addItem(Plant plant) {
    if (_items.containsKey(plant.plantId)) {
      // increase quantity
      _items.update(
        plant.plantId,
        (existing) => CartItem(
          plant: existing.plant,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      // add new item
      _items.putIfAbsent(
        plant.plantId,
        () => CartItem(plant: plant, quantity: 1),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(int plantId) {
    if (!_items.containsKey(plantId)) return;
    if (_items[plantId]!.quantity > 1) {
      _items.update(
        plantId,
        (existing) => CartItem(
          plant: existing.plant,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(plantId);
    }
    notifyListeners();
  }

  void removeItem(int plantId) {
    _items.remove(plantId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class CartItem {
  final Plant plant;
  final int quantity;

  CartItem({required this.plant, required this.quantity});
}
