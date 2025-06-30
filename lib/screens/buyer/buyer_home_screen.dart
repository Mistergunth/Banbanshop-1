import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../providers/buyer_provider.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shop_card.dart';
import 'location_selection_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  _BuyerHomeScreenState createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    final buyerProvider = Provider.of<BuyerProvider>(context, listen: false);
    try {
      await buyerProvider.loadInitialData();
    } catch (e) {
      print('Error loading initial data: $e');
      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }
  
  void _onSearchChanged(String query) {
    final buyerProvider = Provider.of<BuyerProvider>(context, listen: false);
    buyerProvider.setSearchQuery(query);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // Load more data when user scrolls to 80% of the list
      _loadMoreData();
    }
  }
  
  Future<void> _loadMoreData() async {
    final buyerProvider = Provider.of<BuyerProvider>(context, listen: false);
    if (!buyerProvider.isLoadingMore) {
      await buyerProvider.loadMoreData();
    }
  }
  
  void _toggleViewMode() {
    final buyerProvider = Provider.of<BuyerProvider>(context, listen: false);
    buyerProvider.toggleViewMode();
  }
  
  void _onCategorySelected(ProductCategory category) {
    final buyerProvider = Provider.of<BuyerProvider>(context, listen: false);
    buyerProvider.setSelectedCategory(category);
    
    // Scroll to products section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      
      _scrollController.animateTo(
        position.dy + screenHeight * 0.6,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerProvider>(
      builder: (context, buyerProvider, child) {
        final selectedProvince = buyerProvider.selectedProvince;
        final selectedCategory = buyerProvider.selectedCategory;
        
        return Scaffold(
          appBar: CustomAppBar(
            title: selectedProvince?.name ?? 'บ้านบ้านช็อป',
            actions: [
              IconButton(
                icon: const Icon(Icons.location_on_outlined),
                onPressed: () {
                  // Navigate to location selection
                  Navigator.pushReplacementNamed(context, '/buyer/location');
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  // Navigate to cart
                  Navigator.pushNamed(context, '/buyer/cart');
                },
              ),
            ],
          ),
          body: Consumer<BuyerProvider>(
            builder: (context, buyerProvider, _) {
              if (buyerProvider.isLoading && buyerProvider.products.isEmpty) {
                return _buildLoadingShimmer();
              }
              
              return RefreshIndicator(
                onRefresh: _loadInitialData,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Location bar
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16.0, color: Colors.grey),
                            const SizedBox(width: 4.0),
                            Expanded(
                              child: Text(
                                selectedProvince?.name ?? 'เลือกสถานที่',
                                style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to location selection
                                Navigator.pushReplacementNamed(context, '/buyer/location');
                              },
                              child: const Text('เปลี่ยน', style: TextStyle(fontSize: 14.0)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search bar
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'ค้นหาสินค้าหรือร้านค้า',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    ),

                    // Categories horizontal list
                    Consumer<BuyerProvider>(
                      builder: (context, buyerProvider, _) {
                        if (buyerProvider.categories.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        }

                        return SliverToBoxAdapter(
                          child: SizedBox(
                            height: 100.0,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              itemCount: buyerProvider.categories.length,
                              itemBuilder: (context, index) {
                                final category = buyerProvider.categories[index];
                                final isSelected = selectedCategory?.id == category.id;
                                return _buildCategoryItem(category, isSelected: isSelected);
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    // Section title and view toggle
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              buyerProvider.viewMode == 'products'
                                  ? 'สินค้าแนะนำ'
                                  : 'ร้านค้าแนะนำ',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                buyerProvider.viewMode == 'products'
                                    ? Icons.store_outlined
                                    : Icons.shopping_bag_outlined,
                              ),
                              onPressed: _toggleViewMode,
                              tooltip: 'สลับมุมมอง',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Products or Shops grid
                    Consumer<BuyerProvider>(
                      builder: (context, buyerProvider, _) {
                        return buyerProvider.viewMode == 'products'
                            ? _buildProductGrid()
                            : _buildShopGrid();
                      },
                    ),

                    // Loading indicator for pagination
                    if (buyerProvider.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(ProductCategory category, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor.withOpacity(0.1) 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                border: isSelected 
                    ? Border.all(color: Theme.of(context).primaryColor, width: 2) 
                    : null,
              ),
              child: Text(
                category.icon ?? '📦',
                style: const TextStyle(fontSize: 30),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar placeholder
            Container(
              margin: const EdgeInsets.all(16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            
            // Categories placeholder
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 50,
                          height: 10,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Products grid placeholder
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 50,
                  height: 10,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProductGrid() {
    return Consumer<BuyerProvider>(
      builder: (context, buyerProvider, _) {
        if (buyerProvider.products.isEmpty && buyerProvider.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (buyerProvider.products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'ไม่พบสินค้า',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= buyerProvider.products.length) {
                  // Show loading indicator at the bottom if loading more
                  if (buyerProvider.isLoadingMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return null; // Reached the end
                }

                final product = buyerProvider.products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    // Navigate to product detail
                    // Navigator.pushNamed(context, '/buyer/product/${product.id}');
                  },
                );
              },
              childCount: buyerProvider.products.length + (buyerProvider.isLoadingMore ? 1 : 0),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildShopGrid() {
    return Consumer<BuyerProvider>(
      builder: (context, buyerProvider, _) {
        if (buyerProvider.shops.isEmpty && buyerProvider.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (buyerProvider.shops.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'ไม่พบร้านค้า',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= buyerProvider.shops.length) {
                  // Show loading indicator at the bottom if loading more
                  if (buyerProvider.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return null; // Reached the end
                }

                final shop = buyerProvider.shops[index];
                return ShopCard(
                  shop: shop,
                  onTap: () {
                    // Navigate to shop detail
                    // Navigator.pushNamed(context, '/buyer/shop/${shop.id}');
                  },
                  isFavorite: buyerProvider.favoriteShopIds.contains(shop.id),
                  onFavoritePressed: () {
                    // Toggle favorite
                    buyerProvider.toggleFavoriteShop(shop.id);
                  },
                );
              },
              childCount: buyerProvider.shops.length + (buyerProvider.isLoadingMore ? 1 : 0),
            ),
          ),
        );
      },
    );
  }
}
