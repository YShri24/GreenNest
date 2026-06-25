import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:greennest/models/plant.dart';
import 'package:greennest/services/cart_provider.dart';
import 'package:greennest/screens/cart_screen.dart';
import 'package:greennest/widgets/custom_button.dart';
import 'package:greennest/services/api_service.dart';

class DetailsScreen extends StatelessWidget {
  final Plant plant;
  const DetailsScreen({Key? key, required this.plant}) : super(key: key);

  void _showGiftingDialog(BuildContext context) {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final addressController = TextEditingController();
    final messageController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    bool giftWrap = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gift details for recipient',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Recipient Name', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mobileController,
                      decoration: const InputDecoration(labelText: 'Recipient Mobile', prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Recipient Shipping Address', prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(labelText: 'Personal Message (optional)', prefixIcon: Icon(Icons.rate_review)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Delivery Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().add(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Add Gift Wrap (+₹50)'),
                      value: giftWrap,
                      onChanged: (val) {
                        setState(() {
                          giftWrap = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: CustomButton(
                        text: 'Confirm Gift Order',
                        onTap: () async {
                          if (nameController.text.isEmpty || mobileController.text.isEmpty || addressController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required recipient details.')),
                            );
                            return;
                          }

                          try {
                            final apiService = ApiService();
                            await apiService.sendGift({
                              'sender_id': 1,
                              'recipient_name': nameController.text,
                              'recipient_mobile': mobileController.text,
                              'recipient_address': addressController.text,
                              'plant_id': plant.plantId,
                              'message': messageController.text,
                              'delivery_date': "${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                              'gift_wrap': giftWrap,
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gift Order successfully scheduled for ${nameController.text}!'),
                                backgroundColor: const Color(0xFF0F5132),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to process gift order: $e')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showShareDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suggest to Friend via:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.chat_bubble, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () => _handleShare(context, 'WhatsApp'),
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.blue),
                title: const Text('SMS'),
                onTap: () => _handleShare(context, 'SMS'),
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.red),
                title: const Text('Email'),
                onTap: () => _handleShare(context, 'Email'),
              ),
              ListTile(
                leading: const Icon(Icons.content_copy, color: Colors.grey),
                title: const Text('Copy Link'),
                onTap: () => _handleShare(context, 'Copy Link'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleShare(BuildContext context, String platform) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plant details link copied/shared via $platform!'),
        backgroundColor: const Color(0xFF0F5132),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final primaryColor = const Color(0xFF0F5132);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Stack(
              children: [
                Image.network(
                  plant.imageUrl ?? 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921',
                  height: 380,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 380,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.white.withOpacity(0.9),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.5, 0.92, 1],
                    ),
                  ),
                ),
              ],
            ),

            // Specs Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                plant.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: plant.stock > 0
                                      ? (plant.stock <= 5 ? Colors.orange[50] : const Color(0xFFE8F5E9))
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  plant.stock > 0
                                      ? (plant.stock <= 5 ? 'Only ${plant.stock} Left' : 'In Stock (${plant.stock})')
                                      : 'Out of Stock',
                                  style: TextStyle(
                                    color: plant.stock > 0
                                        ? (plant.stock <= 5 ? Colors.orange[800] : const Color(0xFF0F5132))
                                        : Colors.red[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '₹${plant.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Specifications icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSpecIcon(Icons.wb_sunny_outlined, 'Sunlight', plant.sunlight ?? 'Indirect'),
                      _buildSpecIcon(Icons.water_drop_outlined, 'Watering', plant.waterFrequency ?? 'As needed'),
                      _buildSpecIcon(Icons.speed, 'Care Level', plant.maintenance),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'About Plant',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plant.description ?? 'A gorgeous addition to enhance your local environment, requiring low maintenance and offering standard aesthetic benefits.',
                    style: const TextStyle(color: Color(0xFF4A5568), height: 1.5, fontSize: 14),
                  ),

                  const SizedBox(height: 32),

                  // Grouped Action Buttons
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: plant.stock > 0 ? 'Buy Now' : 'Out of Stock',
                            isEnabled: plant.stock > 0,
                            icon: plant.stock > 0 ? Icons.shopping_bag_outlined : Icons.block,
                            onTap: () {
                              cart.addItem(plant);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CartScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: plant.stock > 0 ? 'Gift This Plant' : 'Out of Stock',
                                isEnabled: plant.stock > 0,
                                isPrimary: false,
                                icon: Icons.card_giftcard,
                                onTap: () => _showGiftingDialog(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'Suggest to Friend',
                                isPrimary: false,
                                icon: Icons.share_outlined,
                                onTap: () => _showShareDialog(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecIcon(IconData icon, String label, String value) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0F5132), size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
