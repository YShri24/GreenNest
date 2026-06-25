import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:greennest/services/api_service.dart';
import 'package:greennest/services/cart_provider.dart';
import 'package:greennest/services/auth_provider.dart';
import 'package:greennest/models/plant.dart';
import 'package:greennest/screens/browse_screen.dart';
import 'package:greennest/screens/recommendation_screen.dart';
import 'package:greennest/screens/diagnosis_screen.dart';
import 'package:greennest/screens/plant_cards_screen.dart';
import 'package:greennest/screens/details_screen.dart';
import 'package:greennest/screens/cart_screen.dart';
import 'package:greennest/screens/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Plant> _featuredPlants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedPlants();
  }

  Future<void> _loadFeaturedPlants() async {
    try {
      final plants = await _apiService.fetchPlants();
      setState(() {
        _featuredPlants = plants.take(4).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to backend api: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final primaryColor = const Color(0xFF0F5132);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Icon(Icons.spa, color: primaryColor, size: 28),
            const SizedBox(width: 8),
            const Text(
              'GreenNest',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w800,
                fontSize: 22,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        actions: [
          if (auth.role == 'Admin')
            IconButton(
              icon: Icon(Icons.admin_panel_settings, color: primaryColor),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF4A5568)),
            tooltip: 'Logout',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF4A5568)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cart.totalQuantity > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.totalQuantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Gradient
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [primaryColor, const Color(0xFF1E3F20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Let\'s Find Your Perfect Plant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'AI-powered recommendations, plant health diagnoses, and direct gifting delivery.',
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions Category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildActionCard(
                    context,
                    title: 'Buy Plants',
                    subtitle: 'Browse Catalog',
                    icon: Icons.local_mall,
                    color: const Color(0xFFE8F5E9),
                    iconColor: primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BrowseScreen()),
                    ),
                  ),
                  _buildActionCard(
                    context,
                    title: 'AI Assistant',
                    subtitle: 'Find matching plant',
                    icon: Icons.psychology,
                    color: const Color(0xFFE3F2FD),
                    iconColor: Colors.blue[800]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecommendationScreen()),
                    ),
                  ),
                  _buildActionCard(
                    context,
                    title: 'Plant Diagnosis',
                    subtitle: 'Check plant health',
                    icon: Icons.camera_enhance,
                    color: const Color(0xFFFFF3E0),
                    iconColor: Colors.orange[800]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DiagnosisScreen()),
                    ),
                  ),
                  _buildActionCard(
                    context,
                    title: 'My Garden',
                    subtitle: 'Manage plant cards',
                    icon: Icons.eco,
                    color: const Color(0xFFF3E5F5),
                    iconColor: Colors.purple[800]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlantCardsScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Featured List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Plants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BrowseScreen()),
                      );
                    },
                    child: Text('See All', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Featured Plants list
            _isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _featuredPlants.length,
                    itemBuilder: (context, index) {
                      final plant = _featuredPlants[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              plant.imageUrl ?? 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            plant.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '₹${plant.price.toStringAsFixed(0)} • ${plant.category}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              if (plant.stock <= 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(Out of Stock)',
                                  style: TextStyle(color: Colors.red[800], fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailsScreen(plant: plant),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Color(0xFF4A5568).withOpacity(0.8),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
