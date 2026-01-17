# FlutterFlow Pharmacy E-Commerce Implementation Guide

**Date:** January 12, 2026
**Status:** Ready for FlutterFlow UI Implementation
**Database:** ✅ Complete (14 migrations applied)

## Overview

This guide provides step-by-step instructions for implementing the pharmacy e-commerce UI in FlutterFlow. All backend tables, functions, and security policies are already in place and verified.

## Architecture Summary

```
User Flow:
Browse Products → View Details → Add to Cart/Wishlist → Checkout → Order Tracking

Database Tables (All Ready):
✅ product_categories (15 categories seeded)
✅ product_subcategories
✅ pharmacy_products (empty - pharmacies will add inventory)
✅ user_cart
✅ user_wishlist
✅ user_addresses
✅ pharmacy_orders
✅ pharmacy_order_items
✅ product_reviews
✅ order_tracking
✅ pharmacy_coupons (3 coupons seeded)
✅ coupon_usage
```

## Pages to Create in FlutterFlow

### 1. Product Catalog Page
**File Name:** `ProductCatalogPage`
**Route:** `/pharmacy/products`
**User Roles:** All authenticated users

**UI Components:**
- Search bar with full-text search
- Category filter chips (15 categories)
- Subcategory dropdown
- Sort options (price, name, rating, new arrivals)
- Product grid/list view toggle
- Filter sidebar:
  - Price range slider
  - In stock only checkbox
  - Featured products toggle
  - Trending products toggle
  - Big savings toggle
  - Star rating filter

**Product Card (Grid Item):**
```
┌─────────────────────────┐
│  Product Image          │
│  (200x200)              │
├─────────────────────────┤
│  Product Name           │
│  ⭐⭐⭐⭐☆ (4.2) 45 reviews │
│  1,500 XAF  2,000 XAF   │
│  🏥 Pharmacy Name       │
│  📦 In Stock: 25        │
│  [Add to Cart] [❤️]     │
└─────────────────────────┘
```

**Supabase Queries:**
```dart
// Main query - use product_catalog_view
Query: product_catalog_view
Select: *
Filters:
  - search_vector (full-text search)
  - category_id (equals)
  - subcategory_id (equals)
  - is_available (equals true)
  - requires_prescription (equals false for patients)
  - quantity_in_stock (greater than 0)
  - price (between min and max)
  - average_rating (greater than or equal)
Order By: Selected sort option
Limit: 20 (with pagination)
```

**Custom Actions Needed:**
- `searchProducts(searchTerm)` - Full-text search
- `addToCart(productId, quantity)` - Add item to cart
- `addToWishlist(productId)` - Add to wishlist
- `removeFromWishlist(productId)` - Remove from wishlist

### 2. Product Details Page
**File Name:** `ProductDetailsPage`
**Route:** `/pharmacy/products/:productId`
**User Roles:** All authenticated users

**UI Layout:**
```
┌────────────────────────────────────────┐
│  [< Back]                    [❤️] [🛒] │
├────────────────────────────────────────┤
│                                        │
│  Image Gallery (Swipeable)            │
│  ○ ○ ● ○                               │
│                                        │
├────────────────────────────────────────┤
│  Product Name                          │
│  ⭐⭐⭐⭐☆ 4.2 (45 reviews)              │
│                                        │
│  2,500 XAF  3,000 XAF (-17%)          │
│                                        │
│  🏥 Pharmacy Name                      │
│  📍 Location | ⏱️ Delivery: 2-3 days   │
│                                        │
│  📦 In Stock: 25 units                 │
│  ⚠️ Requires Prescription: No          │
│                                        │
│  Description:                          │
│  [Product description text...]         │
│                                        │
│  Active Ingredients:                   │
│  [Generic name, strength...]           │
│                                        │
│  Dosage & Instructions:                │
│  [Dosage form, instructions...]        │
│                                        │
│  ⚠️ Warnings:                          │
│  [Warnings, side effects...]           │
│                                        │
│  📦 Quantity: [- 1 +]                  │
│                                        │
│  [Add to Cart - 2,500 XAF]            │
│  [Add to Wishlist]                     │
│                                        │
├────────────────────────────────────────┤
│  Reviews (45)                  [Filter]│
│  ⭐⭐⭐⭐⭐ 5 stars: ████████████ 60%   │
│  ⭐⭐⭐⭐☆ 4 stars: ████████     40%   │
│  ...                                   │
│                                        │
│  [User Avatar] John Doe                │
│  ⭐⭐⭐⭐⭐ 2 days ago                    │
│  "Great product, fast delivery..."     │
│  [👍 Helpful (5)] [Report]             │
│                                        │
└────────────────────────────────────────┘
```

**Supabase Queries:**
```dart
// Product details
Query: product_catalog_view
Filter: id (equals productId)
Single: true

// Reviews
Query: product_reviews
Select: *, users(full_name, profile_image)
Filter: product_id (equals productId)
Order By: created_at DESC
Limit: 10 (with load more)

// Review summary
Query: product_review_summary
Filter: product_id (equals productId)
Single: true
```

**Custom Actions Needed:**
- `addToCartWithQuantity(productId, quantity)` - Add with quantity selector
- `checkPrescriptionRequired(productId)` - Verify if prescription needed
- `submitProductReview(productId, rating, comment)` - Submit review
- `markReviewHelpful(reviewId)` - Vote on review

### 3. Shopping Cart Page
**File Name:** `ShoppingCartPage`
**Route:** `/pharmacy/cart`
**User Roles:** Patient, Provider (for personal purchases)

**UI Layout:**
```
┌────────────────────────────────────────┐
│  Shopping Cart (3 items)               │
├────────────────────────────────────────┤
│  🏥 Pharmacy Name #1                   │
│  ┌──────────────────────────────────┐  │
│  │ [Image] Product Name             │  │
│  │ 2,500 XAF x 2                    │  │
│  │ [- 2 +]              [🗑️ Remove] │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ [Image] Product Name 2           │  │
│  │ 1,500 XAF x 1                    │  │
│  │ [- 1 +]              [🗑️ Remove] │  │
│  └──────────────────────────────────┘  │
│  Subtotal: 6,500 XAF                   │
│                                        │
│  🏥 Pharmacy Name #2                   │
│  ┌──────────────────────────────────┐  │
│  │ [Image] Product Name 3           │  │
│  │ 3,000 XAF x 1                    │  │
│  │ [- 1 +]              [🗑️ Remove] │  │
│  └──────────────────────────────────┘  │
│  Subtotal: 3,000 XAF                   │
│                                        │
├────────────────────────────────────────┤
│  🎫 Coupon Code: [___________] [Apply] │
│  Discount: -500 XAF (SAVE500)          │
│                                        │
│  Cart Total: 9,000 XAF                 │
│  Delivery: Calculated at checkout      │
│                                        │
│  [Continue Shopping] [Proceed to Checkout] │
└────────────────────────────────────────┘
```

**Supabase Queries:**
```dart
// Cart items with details
Query: user_cart_with_details
Filter: user_id (equals currentUser)
Order By: created_at DESC

// Calculate totals
Function: calculate_cart_total
Parameters: user_id
Returns: {subtotal, discount, total}

// Validate coupon
Function: validate_coupon_code
Parameters: {code, user_id}
Returns: {valid, discount_type, discount_value, message}
```

**Custom Actions Needed:**
- `updateCartQuantity(cartItemId, quantity)` - Update item quantity
- `removeFromCart(cartItemId)` - Remove item
- `applyCouponCode(code)` - Apply discount
- `removeCouponCode()` - Remove applied coupon
- `calculateCartTotal()` - Get totals with discount
- `validateStockAvailability()` - Check if items still in stock
- `groupCartByPharmacy()` - Group items by pharmacy for display

### 4. Checkout Page
**File Name:** `CheckoutPage`
**Route:** `/pharmacy/checkout`
**User Roles:** Patient, Provider (for personal purchases)

**UI Layout (Multi-Step):**

**Step 1: Delivery Address**
```
┌────────────────────────────────────────┐
│  Checkout (Step 1 of 3)                │
│  ● ○ ○  Delivery | Payment | Review    │
├────────────────────────────────────────┤
│  Delivery Address                       │
│                                        │
│  📍 Saved Addresses:                   │
│  ┌──────────────────────────────────┐  │
│  │ ○ Home                           │  │
│  │   123 Main St, Yaoundé           │  │
│  │   +237 6XX XXX XXX               │  │
│  │   [Edit] [Delete]                │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ ● Work (Selected)                │  │
│  │   456 Office Blvd, Douala        │  │
│  │   +237 6XX XXX XXX               │  │
│  │   [Edit] [Delete]                │  │
│  └──────────────────────────────────┘  │
│                                        │
│  [+ Add New Address]                   │
│                                        │
│  [Back to Cart] [Continue to Payment]  │
└────────────────────────────────────────┘
```

**Step 2: Payment Method**
```
┌────────────────────────────────────────┐
│  Checkout (Step 2 of 3)                │
│  ● ● ○  Delivery | Payment | Review    │
├────────────────────────────────────────┤
│  Payment Method                         │
│                                        │
│  ○ Mobile Money (MTN, Orange)          │
│  ○ Credit/Debit Card                   │
│  ● Cash on Delivery (Selected)         │
│                                        │
│  ⚠️ Note: Prescriptions must be        │
│     presented before delivery          │
│                                        │
│  [Back] [Continue to Review]           │
└────────────────────────────────────────┘
```

**Step 3: Review Order**
```
┌────────────────────────────────────────┐
│  Checkout (Step 3 of 3)                │
│  ● ● ●  Delivery | Payment | Review    │
├────────────────────────────────────────┤
│  Order Summary                          │
│                                        │
│  Delivery Address:                     │
│  456 Office Blvd, Douala               │
│  +237 6XX XXX XXX                      │
│                                        │
│  Payment: Cash on Delivery             │
│                                        │
│  Items (3):                            │
│  🏥 Pharmacy Name #1                   │
│    - Product 1: 2 x 2,500 XAF          │
│    - Product 2: 1 x 1,500 XAF          │
│  🏥 Pharmacy Name #2                   │
│    - Product 3: 1 x 3,000 XAF          │
│                                        │
│  Subtotal: 9,500 XAF                   │
│  Discount (SAVE500): -500 XAF          │
│  Delivery: 1,000 XAF                   │
│  ──────────────────────                │
│  Total: 10,000 XAF                     │
│                                        │
│  ☑️ I agree to terms and conditions    │
│                                        │
│  [Back] [Place Order]                  │
└────────────────────────────────────────┘
```

**Supabase Queries:**
```dart
// Get user addresses
Query: user_addresses
Filter: user_id (equals currentUser)
Order By: is_default DESC, created_at DESC

// Reserve stock for items
Function: reserve_product_stock
Parameters: {product_id, quantity, user_id}
Returns: {success, message}

// Create order
INSERT INTO pharmacy_orders
Fields: user_id, pharmacy_id, delivery_address_id,
        payment_method, total_amount, coupon_code,
        order_status='pending'

INSERT INTO pharmacy_order_items (for each cart item)
Fields: order_id, product_id, quantity, unit_price,
        subtotal

// Apply coupon
Function: apply_coupon_to_order
Parameters: {order_id, coupon_code, user_id}
Returns: {success, discount_amount}

// Clear cart after order
DELETE FROM user_cart
WHERE user_id = currentUser
```

**Custom Actions Needed:**
- `validateCheckoutData()` - Verify all required data present
- `reserveCartStock()` - Reserve stock for all cart items
- `createOrderFromCart(addressId, paymentMethod, couponCode)` - Create order
- `clearCartAfterOrder()` - Empty cart
- `sendOrderNotification(orderId)` - Notify pharmacy and user

### 5. Order History Page
**File Name:** `OrderHistoryPage`
**Route:** `/pharmacy/orders`
**User Roles:** Patient, Provider

**UI Layout:**
```
┌────────────────────────────────────────┐
│  My Orders                    [Filter] │
├────────────────────────────────────────┤
│  Filter: [All▾] [Date▾] [Status▾]     │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ Order #ORD-2026-001              │  │
│  │ Jan 12, 2026 • 10:30 AM          │  │
│  │ 🏥 Pharmacy Name                 │  │
│  │ 3 items • 10,000 XAF             │  │
│  │ Status: 🚚 Out for Delivery      │  │
│  │ [Track Order] [Details]          │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ Order #ORD-2026-002              │  │
│  │ Jan 10, 2026 • 2:15 PM           │  │
│  │ 🏥 Another Pharmacy              │  │
│  │ 1 item • 2,500 XAF               │  │
│  │ Status: ✅ Delivered             │  │
│  │ [Review Products] [Reorder]      │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ Order #ORD-2026-003              │  │
│  │ Jan 8, 2026 • 11:00 AM           │  │
│  │ 🏥 Pharmacy Name                 │  │
│  │ 2 items • 5,000 XAF              │  │
│  │ Status: ❌ Cancelled             │  │
│  │ [Details]                        │  │
│  └──────────────────────────────────┘  │
│                                        │
│  [Load More]                           │
└────────────────────────────────────────┘
```

**Supabase Queries:**
```dart
// Order list
Query: pharmacy_orders_with_details
Filter: user_id (equals currentUser)
Order By: created_at DESC
Limit: 20 (with pagination)

// Order history summary
Query: order_history_summary
Filter: user_id (equals currentUser)
Single: true
Returns: {total_orders, total_spent, avg_order_value}
```

**Custom Actions Needed:**
- `filterOrders(status, dateRange)` - Filter order list
- `reorderPreviousOrder(orderId)` - Add order items back to cart
- `cancelOrder(orderId)` - Cancel pending order

### 6. Order Details Page
**File Name:** `OrderDetailsPage`
**Route:** `/pharmacy/orders/:orderId`
**User Roles:** Patient, Provider

**UI Layout:**
```
┌────────────────────────────────────────┐
│  [< Orders] Order #ORD-2026-001        │
├────────────────────────────────────────┤
│  Order Status: 🚚 Out for Delivery     │
│  Estimated Delivery: Jan 13, 2026      │
│                                        │
│  Order Timeline:                       │
│  ● Placed        Jan 12, 10:30 AM      │
│  ● Confirmed     Jan 12, 10:45 AM      │
│  ● Processing    Jan 12, 2:00 PM       │
│  ● Shipped       Jan 12, 4:30 PM       │
│  ○ Delivered     Pending               │
│                                        │
│  Tracking Number: TRK-123456789        │
│  Courier: DHL Express                  │
│  [Track Package] [Contact Courier]     │
│                                        │
├────────────────────────────────────────┤
│  Items (3)                             │
│  🏥 Pharmacy Name                      │
│  ┌──────────────────────────────────┐  │
│  │ [Image] Product Name             │  │
│  │ Quantity: 2                      │  │
│  │ Price: 2,500 XAF x 2 = 5,000 XAF │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ [Image] Product Name 2           │  │
│  │ Quantity: 1                      │  │
│  │ Price: 1,500 XAF                 │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ [Image] Product Name 3           │  │
│  │ Quantity: 1                      │  │
│  │ Price: 3,000 XAF                 │  │
│  └──────────────────────────────────┘  │
│                                        │
│  Subtotal: 9,500 XAF                   │
│  Discount: -500 XAF                    │
│  Delivery: 1,000 XAF                   │
│  ──────────────────────                │
│  Total: 10,000 XAF                     │
│                                        │
│  Payment: Cash on Delivery             │
│  Delivery Address:                     │
│  456 Office Blvd, Douala               │
│  +237 6XX XXX XXX                      │
│                                        │
│  [Request Invoice] [Need Help?]        │
│  [Cancel Order] (if status=pending)    │
└────────────────────────────────────────┘
```

**Supabase Queries:**
```dart
// Order details
Query: pharmacy_orders_with_details
Filter: id (equals orderId), user_id (equals currentUser)
Single: true

// Order items
Query: pharmacy_order_items
Select: *, pharmacy_products(*)
Filter: order_id (equals orderId)

// Order tracking
Query: order_tracking
Filter: order_id (equals orderId)
Order By: created_at ASC
```

**Custom Actions Needed:**
- `getOrderTrackingStatus(orderId)` - Get current status
- `cancelOrderRequest(orderId, reason)` - Request cancellation
- `contactPharmacy(pharmacyId, orderId)` - Send message to pharmacy
- `downloadInvoice(orderId)` - Generate PDF invoice

### 7. Wishlist Page
**File Name:** `WishlistPage`
**Route:** `/pharmacy/wishlist`
**User Roles:** Patient, Provider

**UI Layout:**
```
┌────────────────────────────────────────┐
│  My Wishlist (8 items)        [Sort▾]  │
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │ [Image]  Product Name            │  │
│  │          2,500 XAF  3,000 XAF    │  │
│  │          ⭐⭐⭐⭐☆ 4.2            │  │
│  │          📦 In Stock             │  │
│  │          🏥 Pharmacy Name        │  │
│  │          [Add to Cart] [🗑️]      │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ [Image]  Product Name 2          │  │
│  │          1,500 XAF               │  │
│  │          ⭐⭐⭐⭐⭐ 4.8           │  │
│  │          ⚠️ Out of Stock         │  │
│  │          🏥 Another Pharmacy     │  │
│  │          [Notify Me] [🗑️]        │  │
│  └──────────────────────────────────┘  │
│                                        │
│  [Add All to Cart]                     │
└────────────────────────────────────────┘
```

**Supabase Queries:**
```dart
// Wishlist items
Query: user_wishlist_with_details
Filter: user_id (equals currentUser)
Order By: created_at DESC
```

**Custom Actions Needed:**
- `moveWishlistToCart(wishlistItemId)` - Move single item to cart
- `addAllWishlistToCart()` - Move all items to cart
- `removeFromWishlist(wishlistItemId)` - Remove item
- `notifyWhenAvailable(productId)` - Set stock alert

### 8. Pharmacy Product Management (Admin)
**File Name:** `PharmacyInventoryPage`
**Route:** `/pharmacy/admin/inventory`
**User Roles:** Facility Admin (pharmacy staff only)

**UI Layout:**
```
┌────────────────────────────────────────┐
│  Pharmacy Inventory         [+ Add Product] │
├────────────────────────────────────────┤
│  Search: [___________]  [Filter▾] [Export] │
│                                        │
│  Low Stock (5) | Expiring Soon (3)    │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ Product Name                     │  │
│  │ Category: Pain Relief            │  │
│  │ Stock: 5 ⚠️ (Reorder at 10)     │  │
│  │ Price: 2,500 XAF (Sale: 2,000)  │  │
│  │ Expires: Jan 30, 2026 ⚠️         │  │
│  │ [Edit] [Restock] [Mark Sale]    │  │
│  └──────────────────────────────────┘  │
│                                        │
│  [Pagination: < 1 2 3 4 5 >]           │
└────────────────────────────────────────┘
```

**Supabase Queries:**
```dart
// Pharmacy products
Query: pharmacy_products
Filter: pharmacy_id (equals userPharmacy)
Order By: created_at DESC

// Low stock products
Query: low_stock_products
Filter: pharmacy_id (equals userPharmacy)

// Expiring products
Query: expiring_products
Filter: pharmacy_id (equals userPharmacy)

// Inventory status
Query: pharmacy_inventory_status
Filter: pharmacy_id (equals userPharmacy)
```

**Custom Actions Needed:**
- `addPharmacyProduct(productData)` - Add new product
- `updateProductStock(productId, quantity)` - Update stock
- `setProductSale(productId, salePrice, endDate)` - Set sale price
- `markProductFeatured(productId)` - Mark as featured
- `bulkImportProducts(csvData)` - Import from CSV

## Custom Actions to Create

Create these in `lib/custom_code/actions/`:

### 1. `add_product_to_cart.dart`
```dart
Future<bool> addProductToCart(
  int productId,
  int quantity,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  // Get user from Supabase
  final userData = await SupaFlow.client
      .from('users')
      .select('id')
      .eq('firebase_uid', user.uid)
      .single();

  final userId = userData['id'];

  // Check if product already in cart
  final existingCart = await SupaFlow.client
      .from('user_cart')
      .select('id, quantity')
      .eq('user_id', userId)
      .eq('product_id', productId)
      .maybeSingle();

  if (existingCart != null) {
    // Update quantity
    await SupaFlow.client.from('user_cart').update({
      'quantity': existingCart['quantity'] + quantity,
    }).eq('id', existingCart['id']);
  } else {
    // Insert new cart item
    await SupaFlow.client.from('user_cart').insert({
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    });
  }

  return true;
}
```

### 2. `add_product_to_wishlist.dart`
```dart
Future<bool> addProductToWishlist(int productId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final userData = await SupaFlow.client
      .from('users')
      .select('id')
      .eq('firebase_uid', user.uid)
      .single();

  final userId = userData['id'];

  // Check if already in wishlist
  final existing = await SupaFlow.client
      .from('user_wishlist')
      .select('id')
      .eq('user_id', userId)
      .eq('product_id', productId)
      .maybeSingle();

  if (existing != null) {
    return false; // Already in wishlist
  }

  await SupaFlow.client.from('user_wishlist').insert({
    'user_id': userId,
    'product_id': productId,
  });

  return true;
}
```

### 3. `calculate_cart_totals.dart`
```dart
Future<Map<String, dynamic>> calculateCartTotals(
  String? couponCode,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  final userData = await SupaFlow.client
      .from('users')
      .select('id')
      .eq('firebase_uid', user.uid)
      .single();

  final userId = userData['id'];

  // Use database function to calculate totals
  final result = await SupaFlow.client.rpc(
    'calculate_cart_total',
    params: {'p_user_id': userId},
  );

  double subtotal = (result as num).toDouble();
  double discount = 0.0;
  String? appliedCoupon;

  // Validate and apply coupon if provided
  if (couponCode != null && couponCode.isNotEmpty) {
    final couponResult = await SupaFlow.client.rpc(
      'validate_coupon_code',
      params: {
        'p_coupon_code': couponCode,
        'p_user_id': userId,
        'p_order_total': subtotal,
      },
    );

    if (couponResult['is_valid'] == true) {
      final discountType = couponResult['discount_type'];
      final discountValue = couponResult['discount_value'];

      if (discountType == 'percentage') {
        discount = subtotal * (discountValue / 100);
      } else {
        discount = discountValue.toDouble();
      }

      appliedCoupon = couponCode;
    }
  }

  final total = subtotal - discount;

  return {
    'subtotal': subtotal,
    'discount': discount,
    'total': total,
    'appliedCoupon': appliedCoupon,
  };
}
```

### 4. `create_pharmacy_order.dart`
```dart
Future<Map<String, dynamic>> createPharmacyOrder(
  int deliveryAddressId,
  String paymentMethod,
  String? couponCode,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {'success': false, 'error': 'Not authenticated'};

  final userData = await SupaFlow.client
      .from('users')
      .select('id')
      .eq('firebase_uid', user.uid)
      .single();

  final userId = userData['id'];

  try {
    // Get cart items
    final cartItems = await SupaFlow.client
        .from('user_cart_with_details')
        .select()
        .eq('user_id', userId);

    if (cartItems.isEmpty) {
      return {'success': false, 'error': 'Cart is empty'};
    }

    // Calculate totals
    final totals = await calculateCartTotals(couponCode);

    // Group by pharmacy
    final Map<int, List<dynamic>> itemsByPharmacy = {};
    for (var item in cartItems) {
      final pharmacyId = item['pharmacy_id'] as int;
      itemsByPharmacy.putIfAbsent(pharmacyId, () => []).add(item);
    }

    final List<String> orderNumbers = [];

    // Create order for each pharmacy
    for (var entry in itemsByPharmacy.entries) {
      final pharmacyId = entry.key;
      final items = entry.value;

      // Calculate pharmacy subtotal
      double pharmacyTotal = 0;
      for (var item in items) {
        pharmacyTotal += (item['sale_price'] ?? item['price']) * item['quantity'];
      }

      // Generate order number
      final orderNumber = await SupaFlow.client.rpc('generate_order_number');

      // Create order
      final order = await SupaFlow.client.from('pharmacy_orders').insert({
        'user_id': userId,
        'pharmacy_id': pharmacyId,
        'order_number': orderNumber,
        'delivery_address_id': deliveryAddressId,
        'payment_method': paymentMethod,
        'subtotal_amount': pharmacyTotal,
        'total_amount': pharmacyTotal,
        'order_status': 'pending',
        'payment_status': paymentMethod == 'cash_on_delivery' ? 'pending' : 'unpaid',
      }).select().single();

      final orderId = order['id'];
      orderNumbers.add(orderNumber);

      // Create order items
      for (var item in items) {
        await SupaFlow.client.from('pharmacy_order_items').insert({
          'order_id': orderId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'unit_price': item['sale_price'] ?? item['price'],
          'subtotal': (item['sale_price'] ?? item['price']) * item['quantity'],
        });

        // Reserve stock
        await SupaFlow.client.rpc(
          'reserve_product_stock',
          params: {
            'p_product_id': item['product_id'],
            'p_quantity': item['quantity'],
            'p_user_id': userId,
          },
        );
      }

      // Apply coupon if provided
      if (couponCode != null && couponCode.isNotEmpty) {
        await SupaFlow.client.rpc(
          'apply_coupon_to_order',
          params: {
            'p_order_id': orderId,
            'p_coupon_code': couponCode,
            'p_user_id': userId,
          },
        );
      }

      // Create initial tracking entry
      await SupaFlow.client.from('order_tracking').insert({
        'order_id': orderId,
        'status': 'pending',
        'notes': 'Order placed successfully',
      });
    }

    // Clear cart
    await SupaFlow.client
        .from('user_cart')
        .delete()
        .eq('user_id', userId);

    return {
      'success': true,
      'orderNumbers': orderNumbers,
      'message': 'Orders created successfully',
    };
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

### 5. `search_products_fulltext.dart`
```dart
Future<List<dynamic>> searchProductsFulltext(
  String searchTerm,
  int? categoryId,
  double? minPrice,
  double? maxPrice,
  double? minRating,
  bool? inStockOnly,
) async {
  var query = SupaFlow.client.from('product_catalog_view').select();

  // Full-text search
  if (searchTerm.isNotEmpty) {
    query = query.textSearch('search_vector', searchTerm);
  }

  // Filters
  if (categoryId != null) {
    query = query.eq('category_id', categoryId);
  }

  if (minPrice != null) {
    query = query.gte('price', minPrice);
  }

  if (maxPrice != null) {
    query = query.lte('price', maxPrice);
  }

  if (minRating != null) {
    query = query.gte('average_rating', minRating);
  }

  if (inStockOnly == true) {
    query = query.gt('quantity_in_stock', 0);
  }

  query = query.eq('is_available', true);

  final results = await query.order('created_at', ascending: false);

  return results;
}
```

### 6. `get_nearby_pharmacies_with_products.dart`
```dart
Future<List<dynamic>> getNearbyPharmaciesWithProducts(
  double latitude,
  double longitude,
  double radiusKm,
  int? productId,
) async {
  final result = await SupaFlow.client.rpc(
    'get_nearby_pharmacies',
    params: {
      'user_lat': latitude,
      'user_lng': longitude,
      'radius_km': radiusKm,
    },
  );

  // If productId provided, filter pharmacies that have this product
  if (productId != null) {
    final pharmaciesWithProduct = <dynamic>[];
    for (var pharmacy in result) {
      final products = await SupaFlow.client
          .from('pharmacy_products')
          .select('id')
          .eq('pharmacy_id', pharmacy['id'])
          .eq('id', productId)
          .eq('is_available', true)
          .gt('quantity_in_stock', 0)
          .maybeSingle();

      if (products != null) {
        pharmaciesWithProduct.add(pharmacy);
      }
    }
    return pharmaciesWithProduct;
  }

  return result;
}
```

## App State Variables to Add

Add these to `lib/app_state.dart`:

```dart
// Shopping cart
int cartItemCount = 0;
double cartTotal = 0.0;
String? appliedCouponCode;

// Wishlist
int wishlistItemCount = 0;

// Current order (during checkout)
int? checkoutDeliveryAddressId;
String? checkoutPaymentMethod;
List<dynamic>? checkoutItems;

// Product filters
String? selectedCategory;
String? selectedSubcategory;
double? minPrice;
double? maxPrice;
double? minRating;
bool showInStockOnly = false;
String sortBy = 'newest'; // newest, price_asc, price_desc, rating

// Search
String productSearchTerm = '';
```

## Navigation Integration

Add these routes to your FlutterFlow navigation:

```
/pharmacy/products - Product Catalog
/pharmacy/products/:productId - Product Details
/pharmacy/cart - Shopping Cart
/pharmacy/wishlist - Wishlist
/pharmacy/checkout - Checkout
/pharmacy/orders - Order History
/pharmacy/orders/:orderId - Order Details
/pharmacy/admin/inventory - Pharmacy Inventory (Admin only)
```

Add shopping cart icon to app bar with badge showing `cartItemCount`.

## Notifications Integration

### Push Notifications for Orders

Integrate with existing Firebase Functions to send notifications:

**Order Created:**
```javascript
{
  title: "Order Confirmed!",
  body: "Your order #ORD-2026-001 has been placed successfully.",
  data: {
    type: "order_update",
    orderId: orderId,
    status: "pending"
  }
}
```

**Order Status Updates:**
```javascript
{
  title: "Order Update",
  body: "Your order #ORD-2026-001 is now out for delivery!",
  data: {
    type: "order_update",
    orderId: orderId,
    status: "shipped"
  }
}
```

### Real-time Updates

Subscribe to order tracking changes:

```dart
SupaFlow.client
  .from('order_tracking')
  .stream(primaryKey: ['id'])
  .eq('order_id', orderId)
  .listen((data) {
    // Update UI with new tracking status
  });
```

## Testing Checklist

### Product Browsing
- [ ] Product catalog loads with categories
- [ ] Full-text search works
- [ ] Category filtering works
- [ ] Price range filtering works
- [ ] Sort options work
- [ ] Product images load
- [ ] Pagination works
- [ ] Featured products show badge
- [ ] Sale prices display correctly

### Product Details
- [ ] All product information displays
- [ ] Image gallery works
- [ ] Add to cart with quantity works
- [ ] Add to wishlist works
- [ ] Reviews load and display
- [ ] Review submission works
- [ ] Prescription requirement shows

### Shopping Cart
- [ ] Cart items display with details
- [ ] Quantity update works
- [ ] Remove item works
- [ ] Cart groups by pharmacy
- [ ] Coupon code validation works
- [ ] Totals calculate correctly
- [ ] Empty cart message shows

### Checkout
- [ ] Address selection works
- [ ] New address creation works
- [ ] Payment method selection works
- [ ] Order review shows all details
- [ ] Stock validation works
- [ ] Order creation succeeds
- [ ] Cart clears after order
- [ ] Confirmation shown

### Orders
- [ ] Order list loads
- [ ] Order filtering works
- [ ] Order details display
- [ ] Tracking timeline shows
- [ ] Reorder works
- [ ] Cancel order works (if pending)

### Wishlist
- [ ] Wishlist items display
- [ ] Move to cart works
- [ ] Remove item works
- [ ] Stock status shows
- [ ] Add all to cart works

### Admin Inventory
- [ ] Product list loads for pharmacy
- [ ] Add new product works
- [ ] Edit product works
- [ ] Stock update works
- [ ] Set sale price works
- [ ] Low stock alerts show
- [ ] Expiring products show

## Security Considerations

All RLS policies are already in place:

**user_cart:** Users can only see/modify their own cart
**user_wishlist:** Users can only see/modify their own wishlist
**user_addresses:** Users can only see/modify their own addresses
**pharmacy_orders:** Users see their orders; pharmacies see orders for their pharmacy
**pharmacy_order_items:** Accessible via parent order permissions
**pharmacy_products:** Pharmacies can only edit their own products; all users can view
**product_reviews:** Users can only delete their own reviews; all can view

**DO NOT bypass RLS** - always use authenticated user context.

## Performance Optimizations

1. **Pagination:** Use `limit` and `offset` for large lists (20 items per page)
2. **Image optimization:** Use CloudFront or CDN for product images
3. **Caching:** Cache category list (updates rarely)
4. **Lazy loading:** Load product images as user scrolls
5. **Debouncing:** Debounce search input (300ms)
6. **Indexes:** All necessary indexes already created (81 total)

## Next Steps

1. ✅ Database schema - **Complete**
2. ✅ Seed data - **Complete**
3. 📱 **Create pages in FlutterFlow** - Use this guide
4. 🔧 Create custom actions - Use code snippets above
5. 🧪 Test all flows end-to-end
6. 📸 Add product images to test data
7. 💳 Integrate payment gateway (Mobile Money, Cards)
8. 📧 Email notifications for orders
9. 📊 Analytics tracking
10. 🚀 Production deployment

## Support Resources

- **Database Documentation:** `PHARMACY_ECOMMERCE_INSTALLATION_COMPLETE.md`
- **Migration Files:** `supabase/migrations/2026011*_*.sql`
- **Verification Scripts:** `verify_pharmacy_system.js`, `check_products.js`
- **FlutterFlow Docs:** https://docs.flutterflow.io
- **Supabase Docs:** https://supabase.com/docs

---

**Ready to implement!** Follow this guide step-by-step in FlutterFlow to build the complete pharmacy e-commerce experience.
