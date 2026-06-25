import 'package:flutter/material.dart';
import 'package:greennest/services/api_service.dart';
import 'package:greennest/models/plant.dart';
import 'package:greennest/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isUploadingImage = false;

  // Add Plant Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Indoor');
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '10');
  final _sunlightController = TextEditingController(text: 'Indirect');
  final _waterFreqController = TextEditingController(text: 'Weekly');
  final _imageUrlController = TextEditingController(text: 'https://images.unsplash.com/photo-1596436889106-be35e843f974?auto=format&fit=crop&q=80&w=400');

  Future<void> _pickAndUploadPlantImage() async {
    final picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() => _isUploadingImage = true);
        final bytes = await file.readAsBytes();
        final url = await _apiService.uploadImage(bytes, file.name);
        setState(() {
          _imageUrlController.text = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  // Selected Tags
  final List<String> _selectedPurposes = [];
  final List<String> _selectedLocations = [];
  final List<String> _selectedLights = [];
  final List<String> _selectedSeasons = [];
  String _selectedMaintenance = 'Low';
  final List<String> _selectedGiftFors = [];
  final List<String> _selectedOccasions = [];

  // Catalog Plants and Edit variables
  List<Plant> _catalogPlants = [];
  Plant? _editingPlant;
  bool _isUploadingEditImage = false;

  // Edit Plant Form Controllers
  final _editFormKey = GlobalKey<FormState>();
  final _editNameController = TextEditingController();
  final _editCategoryController = TextEditingController(text: 'Indoor');
  final _editDescController = TextEditingController();
  final _editPriceController = TextEditingController();
  final _editStockController = TextEditingController();
  final _editSunlightController = TextEditingController();
  final _editWaterFreqController = TextEditingController();
  final _editImageUrlController = TextEditingController();
  final List<String> _editSelectedPurposes = [];
  final List<String> _editSelectedLocations = [];
  final List<String> _editSelectedLights = [];
  final List<String> _editSelectedSeasons = [];
  String _editSelectedMaintenance = 'Low';
  final List<String> _editSelectedGiftFors = [];
  final List<String> _editSelectedOccasions = [];

  // Lists of Orders & Gifts
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _gifts = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _apiService.fetchAllOrders();
      final gifts = await _apiService.fetchAllGifts();
      final plants = await _apiService.fetchPlants();
      setState(() {
        _orders = orders;
        _gifts = gifts;
        _catalogPlants = plants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Fail silently or mock
    }
  }

  Future<void> _submitPlantForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final payload = {
        'name': _nameController.text,
        'category': _categoryController.text,
        'description': _descController.text.isEmpty ? null : _descController.text,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'sunlight': _sunlightController.text,
        'water_frequency': _waterFreqController.text,
        'image_url': _imageUrlController.text,
        'purpose': _selectedPurposes,
        'location': _selectedLocations,
        'light': _selectedLights,
        'season': _selectedSeasons,
        'maintenance': _selectedMaintenance,
        'gift_for': _selectedGiftFors,
        'occasion': _selectedOccasions,
      };

      await _apiService.createPlant(payload);
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plant "${_nameController.text}" successfully added to inventory!'),
          backgroundColor: const Color(0xFF0F5132),
        ),
      );

      // Reset fields
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      setState(() {
        _selectedPurposes.clear();
        _selectedLocations.clear();
        _selectedLights.clear();
        _selectedSeasons.clear();
        _selectedGiftFors.clear();
        _selectedOccasions.clear();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add plant to catalog: $e')),
      );
    }
  }

  void _startEditingPlant(Plant plant) {
    setState(() {
      _editingPlant = plant;
      _editNameController.text = plant.name;
      _editCategoryController.text = plant.category;
      _editPriceController.text = plant.price.toStringAsFixed(2);
      _editStockController.text = plant.stock.toString();
      _editSunlightController.text = plant.sunlight ?? '';
      _editWaterFreqController.text = plant.waterFrequency ?? '';
      _editImageUrlController.text = plant.imageUrl ?? '';
      _editDescController.text = plant.description ?? '';
      
      _editSelectedPurposes.clear();
      _editSelectedPurposes.addAll(plant.purpose);
      _editSelectedLocations.clear();
      _editSelectedLocations.addAll(plant.location);
      _editSelectedLights.clear();
      _editSelectedLights.addAll(plant.light);
      _editSelectedSeasons.clear();
      _editSelectedSeasons.addAll(plant.season);
      _editSelectedMaintenance = plant.maintenance;
      _editSelectedGiftFors.clear();
      _editSelectedGiftFors.addAll(plant.giftFor);
      _editSelectedOccasions.clear();
      _editSelectedOccasions.addAll(plant.occasion);
    });
  }

  Future<void> _pickAndUploadEditPlantImage() async {
    final picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() => _isUploadingEditImage = true);
        final bytes = await file.readAsBytes();
        final url = await _apiService.uploadImage(bytes, file.name);
        setState(() {
          _editImageUrlController.text = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit image uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload edit image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingEditImage = false);
      }
    }
  }

  Future<void> _submitEditPlantForm() async {
    if (!_editFormKey.currentState!.validate()) return;
    if (_editingPlant == null) return;
    
    setState(() => _isLoading = true);
    try {
      final payload = {
        'name': _editNameController.text,
        'category': _editCategoryController.text,
        'description': _editDescController.text.isEmpty ? null : _editDescController.text,
        'price': double.parse(_editPriceController.text),
        'stock': int.parse(_editStockController.text),
        'sunlight': _editSunlightController.text,
        'water_frequency': _editWaterFreqController.text,
        'image_url': _editImageUrlController.text,
        'purpose': _editSelectedPurposes,
        'location': _editSelectedLocations,
        'light': _editSelectedLights,
        'season': _editSelectedSeasons,
        'maintenance': _editSelectedMaintenance,
        'gift_for': _editSelectedGiftFors,
        'occasion': _editSelectedOccasions,
      };

      await _apiService.updatePlant(_editingPlant!.plantId, payload);
      
      setState(() {
        _editingPlant = null;
      });
      
      await _loadAdminData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plant catalog details updated successfully!'),
            backgroundColor: Color(0xFF0F5132),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update plant: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F5132);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
          title: const Text(
            'Owner Admin Panel',
            style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: const Color(0xFF718096),
            indicatorColor: primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.inventory), text: 'Manage Catalog'),
              Tab(icon: Icon(Icons.add_business), text: 'Add Plant'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
              Tab(icon: Icon(Icons.card_giftcard), text: 'Gifts'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildManageCatalogTab(primaryColor),
                  _buildAddPlantTab(primaryColor),
                  _buildOrdersTab(primaryColor),
                  _buildGiftsTab(primaryColor),
                ],
              ),
      ),
    );
  }

  Widget _buildAddPlantTab(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Plant For Sale',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 16),
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Plant Name', prefixIcon: Icon(Icons.eco)),
              validator: (val) => (val == null || val.isEmpty) ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _categoryController.text,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
              items: ['Indoor', 'Outdoor', 'Medicinal']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => _categoryController.text = val ?? 'Indoor',
            ),
            const SizedBox(height: 12),

            // Price & Stock row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter price';
                      if (double.tryParse(val) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(labelText: 'Stock Qty', prefixIcon: Icon(Icons.inventory_2)),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter stock';
                      if (int.tryParse(val) == null) return 'Enter a valid integer';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Specs
            TextFormField(
              controller: _sunlightController,
              decoration: const InputDecoration(labelText: 'Sunlight Requirements', prefixIcon: Icon(Icons.wb_sunny)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _waterFreqController,
              decoration: const InputDecoration(labelText: 'Water Frequency', prefixIcon: Icon(Icons.water_drop)),
            ),
            const SizedBox(height: 12),
            _buildImageUploadSection(primaryColor),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // --- Multi-Select Tag Chip Checklists ---
            _buildSectionHeader('Purpose Tags'),
            _buildTagsWrap(['Air Purification', 'Decoration', 'Good Luck', 'Stress Relief', 'Medicinal Use', 'Balcony Beautification'], _selectedPurposes, primaryColor),

            _buildSectionHeader('Placement Locations'),
            _buildTagsWrap(['Bedroom', 'Living Room', 'Balcony', 'Office Desk', 'Garden', 'Kitchen', 'Terrace'], _selectedLocations, primaryColor),

            _buildSectionHeader('Sunlight Level Tags'),
            _buildTagsWrap(['Low', 'Medium', 'Bright Indirect', 'Direct Sunlight'], _selectedLights, primaryColor),

            _buildSectionHeader('Seasons'),
            _buildTagsWrap(['Summer', 'Monsoon', 'Winter', 'All Season'], _selectedSeasons, primaryColor),

            _buildSectionHeader('Maintenance Tier'),
            DropdownButtonFormField<String>(
              value: _selectedMaintenance,
              decoration: const InputDecoration(labelText: 'Maintenance Care Level', prefixIcon: Icon(Icons.build_circle)),
              items: ['Low', 'Medium', 'High']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedMaintenance = val ?? 'Low'),
            ),
            const SizedBox(height: 16),

            _buildSectionHeader('Ideal Gift For'),
            _buildTagsWrap(['Friend', 'Mother', 'Father', 'Sister', 'Brother', 'Spouse', 'Colleague', 'Teacher', 'Other'], _selectedGiftFors, primaryColor),

            _buildSectionHeader('Best Occasions'),
            _buildTagsWrap(['Birthday', 'Anniversary', 'Housewarming', 'Wedding', 'Graduation', 'Festival', 'Thank You', 'Get Well Soon', 'Just Because'], _selectedOccasions, primaryColor),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Publish Plant to Shop',
                onTap: _submitPlantForm,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection(Color primaryColor) {
    final currentUrl = _imageUrlController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plant Image',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A5568)),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Box
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: currentUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        currentUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.image, color: Colors.grey, size: 40),
            ),
            const SizedBox(width: 16),
            // Actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isUploadingImage
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _pickAndUploadPlantImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select an image from your device or paste a URL below:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _imageUrlController,
          decoration: const InputDecoration(
            labelText: 'Image Link URL (alternative)',
            prefixIcon: Icon(Icons.link),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildOrdersTab(Color primaryColor) {
    if (_orders.isEmpty) {
      return const Center(child: Text('No orders placed yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final List<dynamic> items = order['items'] ?? [];
        final date = DateTime.parse(order['order_date']);

        final rawTotal = order['total_amount'];
        final double totalAmount = rawTotal is String 
            ? double.parse(rawTotal) 
            : (rawTotal as num).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order['order_id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${date.day}/${date.month}/${date.year} • Status: ${order['status']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Divider(),
                const SizedBox(height: 6),
                const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                ...items.map((item) {
                  final rawPrice = item['price'];
                  final double itemPrice = rawPrice is String 
                      ? double.parse(rawPrice) 
                      : (rawPrice as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '• ${item['plant']['name']} (x${item['quantity']}) @ ₹${itemPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGiftsTab(Color primaryColor) {
    if (_gifts.isEmpty) {
      return const Center(child: Text('No scheduled gifts yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _gifts.length,
      itemBuilder: (context, index) {
        final gift = _gifts[index];
        final date = DateTime.parse(gift['delivery_date']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('To: ${gift['recipient_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      gift['status'],
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Delivery Scheduled: ${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'Address: ${gift['recipient_address']}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.card_giftcard, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text('Gift: ${gift['plant']['name']} (Wrapped: ${gift['gift_wrap'] ? "Yes" : "No"})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (gift['message'] != null && gift['message'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '"${gift['message']}"',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF4A5568), fontSize: 12),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A5568)),
      ),
    );
  }

  Widget _buildTagsWrap(List<String> options, List<String> selections, Color primaryColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((opt) {
        final isSelected = selections.contains(opt);
        return FilterChip(
          label: Text(opt, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF4A5568))),
          selected: isSelected,
          selectedColor: primaryColor,
          checkmarkColor: Colors.white,
          onSelected: (val) {
            setState(() {
              if (val) {
                selections.add(opt);
              } else {
                selections.remove(opt);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildManageCatalogTab(Color primaryColor) {
    if (_editingPlant != null) {
      return _buildEditPlantForm(_editingPlant!, primaryColor);
    }

    if (_catalogPlants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No products in catalog', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadAdminData,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Refresh Catalog'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _catalogPlants.length,
      itemBuilder: (context, index) {
        final plant = _catalogPlants[index];
        final isLowStock = plant.stock <= 5;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    plant.imageUrl ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[200], width: 60, height: 60, child: const Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plant.category} • ₹${plant.price.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLowStock ? Colors.red[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stock: ${plant.stock}',
                              style: TextStyle(
                                color: isLowStock ? Colors.red[800] : Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => _startEditingPlant(plant),
                      tooltip: 'Edit Plant',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deletePlantConfirmation(plant),
                      tooltip: 'Delete Plant',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deletePlantConfirmation(Plant plant) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product?'),
          content: Text('Are you sure you want to permanently remove "${plant.name}" from the GreenNest shop catalog?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _apiService.deletePlant(plant.plantId);
                  await _loadAdminData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${plant.name}" successfully deleted from catalog.'),
                        backgroundColor: const Color(0xFF0F5132),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete plant: $e')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditPlantForm(Plant plant, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _editFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Product #${plant.plantId}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _editingPlant = null),
                  icon: const Icon(Icons.cancel, color: Colors.grey),
                  label: const Text('Cancel Edit', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name
            TextFormField(
              controller: _editNameController,
              decoration: const InputDecoration(labelText: 'Plant Name', prefixIcon: Icon(Icons.eco)),
              validator: (val) => (val == null || val.isEmpty) ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _editCategoryController.text,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
              items: ['Indoor', 'Outdoor', 'Medicinal']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => _editCategoryController.text = val ?? 'Indoor',
            ),
            const SizedBox(height: 12),

            // Price & Stock row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _editPriceController,
                    decoration: const InputDecoration(labelText: 'Price (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter price';
                      if (double.tryParse(val) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _editStockController,
                    decoration: const InputDecoration(labelText: 'Stock Qty', prefixIcon: Icon(Icons.inventory_2)),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter stock';
                      if (int.tryParse(val) == null) return 'Enter a valid integer';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Specs
            TextFormField(
              controller: _editSunlightController,
              decoration: const InputDecoration(labelText: 'Sunlight Requirements', prefixIcon: Icon(Icons.wb_sunny)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _editWaterFreqController,
              decoration: const InputDecoration(labelText: 'Water Frequency', prefixIcon: Icon(Icons.water_drop)),
            ),
            const SizedBox(height: 12),
            _buildEditImageUploadSection(primaryColor),
            const SizedBox(height: 12),
            TextFormField(
              controller: _editDescController,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // --- Multi-Select Tag Chip Checklists ---
            _buildSectionHeader('Purpose Tags'),
            _buildTagsWrap(['Air Purification', 'Decoration', 'Good Luck', 'Stress Relief', 'Medicinal Use', 'Balcony Beautification'], _editSelectedPurposes, primaryColor),

            _buildSectionHeader('Placement Locations'),
            _buildTagsWrap(['Bedroom', 'Living Room', 'Balcony', 'Office Desk', 'Garden', 'Kitchen', 'Terrace'], _editSelectedLocations, primaryColor),

            _buildSectionHeader('Sunlight Level Tags'),
            _buildTagsWrap(['Low', 'Medium', 'Bright Indirect', 'Direct Sunlight'], _editSelectedLights, primaryColor),

            _buildSectionHeader('Seasons'),
            _buildTagsWrap(['Summer', 'Monsoon', 'Winter', 'All Season'], _editSelectedSeasons, primaryColor),

            _buildSectionHeader('Maintenance Tier'),
            DropdownButtonFormField<String>(
              value: _editSelectedMaintenance,
              decoration: const InputDecoration(labelText: 'Maintenance Care Level', prefixIcon: Icon(Icons.build_circle)),
              items: ['Low', 'Medium', 'High']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _editSelectedMaintenance = val ?? 'Low'),
            ),
            const SizedBox(height: 16),

            _buildSectionHeader('Ideal Gift For'),
            _buildTagsWrap(['Friend', 'Mother', 'Father', 'Sister', 'Brother', 'Spouse', 'Colleague', 'Teacher', 'Other'], _editSelectedGiftFors, primaryColor),

            _buildSectionHeader('Best Occasions'),
            _buildTagsWrap(['Birthday', 'Anniversary', 'Housewarming', 'Wedding', 'Graduation', 'Festival', 'Thank You', 'Get Well Soon', 'Just Because'], _editSelectedOccasions, primaryColor),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Save Product Changes',
                onTap: _submitEditPlantForm,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEditImageUploadSection(Color primaryColor) {
    final currentUrl = _editImageUrlController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Plant Image',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A5568)),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: currentUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        currentUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.image, color: Colors.grey, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isUploadingEditImage
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _pickAndUploadEditPlantImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select an image from your device or paste a URL below:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _editImageUrlController,
          decoration: const InputDecoration(
            labelText: 'Image Link URL (alternative)',
            prefixIcon: Icon(Icons.link),
          ),
          onChanged: (val) {
            setState(() {});
          },
        ),
      ],
    );
  }
}
