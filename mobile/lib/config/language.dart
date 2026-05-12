import 'package:flutter/material.dart';

/// Global language notifier — 'en' or 'bn'
final ValueNotifier<String> appLang = ValueNotifier('en');

/// Returns the translated string for [key] based on current language
String S(String key) =>
    AppStrings._t[appLang.value]?[key] ??
    AppStrings._t['en']![key] ??
    key;

class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _t = {
    // ── English ──────────────────────────────────────────────────────────────
    'en': {
      // App
      'app_name': 'SupplyLink',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'back': 'Back',
      'save': 'Save Changes',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'edit': 'Edit',
      'delete': 'Delete',
      'close': 'Close',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'success': 'Success',
      'failed': 'Failed',
      'no_data': 'No data found',
      'server_error': 'Cannot connect to server',
      'fill_all_fields': 'Please fill in all fields',
      'taka': '৳',

      // Language toggle
      'lang_en': 'EN',
      'lang_bn': 'বাং',

      // Categories
      'grocery': 'Grocery',
      'pharmacy': 'Pharmacy',
      'stationary': 'Stationary',
      'hardware': 'Hardware',

      // Units
      'kg': 'kg',
      'litre': 'litre',
      'piece': 'piece',
      'pack': 'pack',

      // Order status
      'pending': 'Pending',
      'accepted': 'Accepted',
      'declined': 'Declined',
      'out_for_delivery': 'Out for Delivery',
      'delivered': 'Delivered',
      'open': 'Open',
      'matched': 'Matched',
      'fulfilled': 'Fulfilled',

      // Welcome
      'tagline': 'Connect · Source · Grow',
      'welcome_desc': 'Direct sourcing for Bangladeshi\nshop owners & suppliers',
      'no_middlemen': 'No Middlemen',
      'near_you': 'Near You',
      'rated': 'Rated',
      'shop_owner': 'Shop Owner',
      'shop_owner_sub': 'Post demands, find suppliers, track orders',
      'stockholder_supplier': 'Stockholder / Supplier',
      'stockholder_sub': 'List your stock, accept orders, deliver',
      'already_account': 'Already have an account? ',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',

      // Login
      'welcome_back': 'Welcome Back!',
      'sign_in_subtitle': 'Sign in to your SupplyLink account',
      'email_or_phone': 'Email or Phone',
      'email_phone_hint': 'Enter your email or 01XXXXXXXXX',
      'password': 'Password',
      'password_hint': 'Enter your password',
      'no_account': "Don't have an account?",
      'login_failed': 'Login failed',

      // Register
      'register_shop_title': 'Create Shop Owner Account',
      'register_shop_sub': 'Fill in your details to get started',
      'register_stock_title': 'Create Supplier Account',
      'register_stock_sub': 'Fill in your details to get started',
      'full_name': 'Full Name',
      'name_hint': 'Your full name',
      'phone_number': 'Phone Number',
      'phone_hint': '01XXXXXXXXX',
      'email': 'Email (optional)',
      'email_hint': 'your@email.com',
      'shop_name': 'Shop Name',
      'shop_name_hint': 'Enter your shop name',
      'shop_category': 'Shop Category',
      'select_category': 'Select category',
      'company_name': 'Company Name',
      'company_hint': 'Your company or business name',
      'product_categories': 'Product Categories',
      'select_categories': 'Select what you supply',
      'create_account': 'Create Account',
      'already_have_account': 'Already have an account?',
      'min_6_chars': 'Password must be at least 6 characters',
      'confirm_password': 'Confirm Password',
      'passwords_no_match': 'Passwords do not match',

      // Shop Owner Dashboard
      'dashboard': 'Dashboard',
      'good_morning': 'Good Morning',
      'good_afternoon': 'Good Afternoon',
      'good_evening': 'Good Evening',
      'open_demands': 'Open Demands',
      'active_orders': 'Active Orders',
      'matched_demands': 'Matched',
      'post_demand': 'Post Demand',
      'my_orders': 'My Orders',
      'my_demands': 'My Demands',
      'browse_stock': 'Browse Stock',
      'quick_actions': 'Quick Actions',
      'recent_demands': 'Recent Demands',
      'recent_orders': 'Recent Orders',
      'unrated_orders': 'Rate Delivered Orders',
      'view_all': 'View All',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',

      // Post Demand
      'post_demand_title': 'Post Demand',
      'select_product_cat': 'Select Product Category',
      'select_product': 'Select Product',
      'select_variant': 'Select Variant',
      'quantity': 'Quantity',
      'quantity_hint': 'Enter quantity',
      'unit': 'Unit',
      'notes': 'Additional Notes',
      'notes_hint': 'Any special requirements...',
      'location': 'Location',
      'detect_location': 'Detect My Location',
      'pick_on_map': 'Pick on Map',
      'post_demand_btn': 'Post Demand',
      'next_btn': 'Next',
      'demand_posted': 'Demand posted successfully!',

      // Matching Suppliers
      'matching_suppliers': 'Matching Suppliers',
      'no_matches': 'No suppliers found nearby',
      'km_away': 'km away',
      'per': 'per',
      'available': 'available',
      'order_now': 'Order Now',
      'sort_distance': 'Nearest',
      'sort_price': 'Cheapest',

      // Order Confirm
      'order_summary': 'Order Summary',
      'delivery_address': 'Delivery Address',
      'delivery_hint': 'Enter full delivery address',
      'total_price': 'Total Price',
      'place_order': 'Place Order',
      'order_placed': 'Order placed successfully!',
      'supplier': 'Supplier',
      'product': 'Product',
      'price_per_unit': 'Price / Unit',

      // Order Status
      'order_status': 'Order Status',
      'order_id': 'Order ID',
      'order_details': 'Order Details',
      'generate_otp': 'Generate OTP',
      'otp_generated': 'OTP generated!',
      'your_otp': 'Your OTP Code',
      'otp_expires': 'Expires in 10 minutes',
      'show_otp_to_delivery': 'Show this code to the delivery person',

      // My Orders
      'my_orders_title': 'My Orders',
      'no_orders': 'No orders yet',
      'rate_supplier': 'Rate Supplier',
      'rating_completed': 'Rating Completed',
      'tap_for_status': 'Tap to track status',

      // Rate Supplier
      'rate_title': 'Rate Supplier',
      'your_rating': 'Your Rating',
      'tap_star': 'Tap a star to rate',
      'write_review': 'Write a review (optional)',
      'review_hint': 'Share your experience...',
      'submit_rating': 'Submit Rating',
      'rating_submitted': 'Rating submitted!',
      'select_rating': 'Please select a rating',

      // My Demands
      'my_demands_title': 'My Demands',
      'no_demands': 'No demands yet',
      'cancel_demand': 'Cancel',
      'demand_cancelled': 'Demand cancelled',
      'view_matches': 'View Matches',
      'post_first_demand': 'Post your first demand',

      // Browse Stock
      'browse_stocks': 'Browse Stocks',
      'search_hint': 'Search products...',
      'filter': 'Filter',
      'no_stocks': 'No stocks available',
      'in_stock': 'In Stock',
      'sold_out': 'Sold Out',

      // Stockholder Dashboard
      'stock_dashboard': 'Supplier Dashboard',
      'active_stock': 'Active Stock',
      'new_orders': 'New Orders',
      'delivered_orders': 'Delivered',
      'post_stock': 'Post Stock',
      'my_stock': 'My Stock',
      'order_inbox': 'Order Inbox',
      'nearby_demands': 'Nearby Demands',
      'earnings': 'Earnings',

      // Post Stock
      'post_stock_title': 'Post Stock',
      'price_hint': 'Enter price',
      'warehouse_area': 'Warehouse Area',
      'stock_posted': 'Stock posted successfully!',
      'additional_notes': 'Additional Notes',

      // My Stock
      'my_stock_title': 'My Stock',
      'no_stock': 'No stock posted yet',
      'edit_stock': 'Edit Stock',
      'delete_stock': 'Delete Stock',
      'delete_confirm': 'Delete this stock item?',
      'qty_available': 'Available',
      'update_stock': 'Update Stock',
      'stock_updated': 'Stock updated!',

      // Order Inbox
      'order_inbox_title': 'Order Inbox',
      'no_incoming': 'No incoming orders',
      'accept': 'Accept',
      'decline': 'Decline',
      'mark_out_for_delivery': 'Out for Delivery',
      'verify_otp_btn': 'Verify OTP',
      'location_hidden': 'Location revealed after acceptance',
      'order_accepted': 'Order accepted!',
      'order_declined': 'Order declined',
      'shop': 'Shop',
      'area': 'Area',

      // Verify OTP
      'verify_otp_title': 'Verify Delivery OTP',
      'enter_otp': 'Enter OTP',
      'otp_hint': '6-digit code',
      'verify_otp': 'Confirm Delivery',
      'otp_verified': 'Delivery confirmed!',
      'invalid_otp': 'Invalid or expired OTP',

      // Nearby Demands
      'nearby_demands_title': 'Nearby Demands',
      'no_nearby': 'No demands found nearby',
      'wants': 'wants',
      'demand_posted_at': 'Posted',

      // Earnings
      'earnings_title': 'Earnings',
      'total_earned': 'Total Earned',
      'this_month': 'This Month',
      'last_month': 'Last Month',
      'platform_fee': 'Platform Fee (2%)',
      'net_earnings': 'Net Earnings',
      'gross': 'Gross',
      'monthly_breakdown': 'Monthly Breakdown',
      'recent_transactions': 'Recent Transactions',
      'no_earnings': 'No earnings yet',

      // Notifications
      'notifications_title': 'Notifications',
      'no_notifications': 'No notifications yet',
      'mark_all_read': 'Mark all as read',
      'could_not_load': 'Could not load notifications',
      'unread': 'Unread',

      // Profile
      'profile_title': 'Profile',
      'edit_profile': 'Edit Profile',
      'verified': 'Verified',
      'not_verified': 'Not Verified',
      'member_since': 'Member since',
      'rating_avg': 'Avg Rating',
      'total_orders': 'Total Orders',
      'district': 'District',
      'address': 'Address',
      'update_profile': 'Update Profile',
      'profile_updated': 'Profile updated!',

      // Auth register extended
      'fill_all_fields_category': 'Fill all fields and pick at least one category',
      'shop_owner_signup': 'Shop Owner Sign Up',
      'create_account_subtitle': 'Create your account to get started',
      'what_do_you_sell': 'What do you sell?',
      'password_min_length': 'Password must be at least 6 characters',
      'cannot_connect': 'Cannot connect to server',
      'stockholder_signup': 'Stockholder Sign Up',
      'join_as_supplier': 'Join as a supplier on SupplyLink',
      'what_do_you_supply': 'What do you supply?',
      'select_all_apply': 'Select all that apply',

      // Shop owner dashboard extended
      'active_demands': 'Active Demands',
      'see_all': 'See All',
      'post_demand_action': 'Post\nDemand',
      'browse_stocks_action': 'Browse\nStocks',
      'my_orders_action': 'My\nOrders',
      'post_new_demand': 'Post New\nDemand',
      'log_out_title': 'Log Out?',
      'log_out_subtitle': 'You will need to sign in again.',
      'log_out': 'Log Out',
      'nav_home': 'Home',
      'nav_demands': 'Demands',
      'nav_orders': 'Orders',
      'nav_profile': 'Profile',
      'nav_my_stock': 'My Stock',

      // Post demand extended
      'post_a_demand': 'Post a Demand',
      'suppliers_respond_subtitle': 'Suppliers near you respond instantly',
      'search_products_hint': 'Search products...',

      // My orders extended
      'my_orders_subtitle': 'Track all your orders',
      'filter_all': 'All',
      'status_pending': 'Pending',
      'status_accepted': 'Accepted',
      'status_on_way': 'On Way',
      'status_delivered': 'Delivered',
      'rate_supplier_btn': 'Rate this Supplier',
      'no_orders_yet': 'No orders yet',
      'no_orders_subtitle': 'Place your first order to get started',

      // My demands extended
      'my_demands_subtitle': 'Track your active demands',
      'new_demand_fab': 'New Demand',
      'no_demands_yet': 'No demands yet',
      'no_demands_subtitle': 'Post your first demand to find suppliers',
      'no_demands_filter': 'No demands in this status',

      // Matching suppliers extended
      'nearby_suppliers': 'Nearby Suppliers',
      'search_supplier_hint': 'Search supplier or area...',
      'sort_nearest': 'Nearest',
      'sort_cheapest': 'Cheapest',
      'sort_top_rated': 'Top Rated',
      'no_suppliers_found': 'No suppliers found',
      'no_suppliers_subtitle': 'Try changing your search or filters',
      'refresh_btn': 'Refresh',

      // Order confirm extended
      'confirm_order': 'Confirm Order',
      'review_place_order': 'Review and place your order',
      'delivery_location': 'Delivery Location',

      // Order status extended
      'order_status_title': 'Order Status',
      'otp_valid_for': 'Valid for 10 minutes',
      'generate_new_code': 'Generate New Code',
      'delivery_progress': 'Delivery Progress',

      // Rate supplier extended
      'rate_supplier_title': 'Rate Supplier',
      'rate_supplier_subtitle': 'Share your delivery experience',
      'submit_review': 'Submit Review',

      // Browse stocks extended
      'browse_stocks_title': 'Browse Stocks',
      'search_stocks_hint': 'Search rice, oil, paint, supplier...',
      'no_stocks_found': 'No stocks found',

      // Stockholder dashboard extended
      'orders_action': 'Orders',
      'post_stock_action': 'Post\nStock',
      'my_stock_action': 'My\nStock',
      'nearby_demands_action': 'Nearby\nDemands',
      'accept_btn': 'Accept',
      'decline_btn': 'Decline',

      // Post stock extended
      'post_stock_btn': 'Post Stock',

      // My stock extended
      'no_stock_yet': 'No stock yet',
      'delete_stock_title': 'Delete this stock?',

      // Order inbox extended
      'order_inbox_subtitle': 'Manage incoming orders',

      // Order detail extended
      'decline_order_title': 'Decline Order?',
      'buyer_info_hidden': 'Buyer info revealed after you accept the order',
      'confirm_delivery_btn': 'Confirm Delivery',
      'accept_order_btn': 'Accept Order',
      'mark_out_delivery': 'Mark Out for Delivery',

      // Verify OTP extended
      'delivered_title': 'Delivered!',
      'otp_verified_message': 'OTP verified. Order has been successfully delivered.',
      'done_btn': 'Done',
      'enter_otp_subtitle': 'Enter OTP from shop owner',
      'enter_6digit_otp': 'Enter 6-Digit OTP',
      'ask_shop_owner_otp': 'Ask the shop owner for their delivery OTP code',

      // Nearby demands extended
      'nearby_demands_subtitle': 'Open demands within 10 km',
      'no_demands_category': 'No demands in this category',

      // Earnings extended
      'my_earnings_title': 'My Earnings',
      'earnings_subtitle': 'Net after 2% platform fee',
      'total_net_earnings': 'Total Net Earnings',
      'net_earnings_label': 'Net Earnings',
      'this_month_label': 'This Month',
      'last_month_label': 'Last Month',
      'could_not_load_earnings': 'Could not load earnings',
      'retry_btn': 'Retry',

      // Notifications extended
      'could_not_load_notifications': 'Could not load notifications',

      // Profile extended
      'verified_badge': 'Verified',
      'edit_profile_btn': 'Edit Profile',

      // Edit profile extended
      'edit_profile_title': 'Edit Profile',
      'edit_profile_subtitle': 'Update your information',
      'save_changes_btn': 'Save Changes',
    },

    // ── বাংলা ─────────────────────────────────────────────────────────────────
    'bn': {
      // App
      'app_name': 'SupplyLink',
      'loading': 'লোড হচ্ছে...',
      'error': 'সমস্যা হয়েছে',
      'retry': 'আবার চেষ্টা করুন',
      'back': 'পেছনে',
      'save': 'পরিবর্তন সংরক্ষণ করুন',
      'cancel': 'বাতিল',
      'submit': 'জমা দিন',
      'edit': 'সম্পাদনা',
      'delete': 'মুছুন',
      'close': 'বন্ধ করুন',
      'confirm': 'নিশ্চিত করুন',
      'yes': 'হ্যাঁ',
      'no': 'না',
      'ok': 'ঠিক আছে',
      'success': 'সফল',
      'failed': 'ব্যর্থ',
      'no_data': 'কোন তথ্য পাওয়া যায়নি',
      'server_error': 'সার্ভারে সংযোগ হচ্ছে না',
      'fill_all_fields': 'সব তথ্য পূরণ করুন',
      'taka': '৳',

      // Language toggle
      'lang_en': 'EN',
      'lang_bn': 'বাং',

      // Categories
      'grocery': 'মুদিখানা',
      'pharmacy': 'ওষুধ',
      'stationary': 'স্টেশনারি',
      'hardware': 'হার্ডওয়্যার',

      // Units
      'kg': 'কেজি',
      'litre': 'লিটার',
      'piece': 'পিস',
      'pack': 'প্যাক',

      // Order status
      'pending': 'অপেক্ষায়',
      'accepted': 'গৃহীত',
      'declined': 'বাতিল',
      'out_for_delivery': 'ডেলিভারিতে আছে',
      'delivered': 'পৌঁছে গেছে',
      'open': 'খোলা',
      'matched': 'মিলেছে',
      'fulfilled': 'পূরণ হয়েছে',

      // Welcome
      'tagline': 'সংযুক্ত · সংগ্রহ · বাড়ান',
      'welcome_desc': 'বাংলাদেশি দোকানদার ও সরবরাহকারীদের\nজন্য সরাসরি পণ্য সংগ্রহ',
      'no_middlemen': 'দালাল নেই',
      'near_you': 'কাছাকাছি',
      'rated': 'রেটিং যুক্ত',
      'shop_owner': 'দোকান মালিক',
      'shop_owner_sub': 'চাহিদা দিন, সরবরাহকারী খুঁজুন, অর্ডার ট্র্যাক করুন',
      'stockholder_supplier': 'স্টকহোল্ডার / সরবরাহকারী',
      'stockholder_sub': 'স্টক দিন, অর্ডার নিন, ডেলিভারি দিন',
      'already_account': 'ইতিমধ্যে অ্যাকাউন্ট আছে? ',
      'sign_in': 'সাইন ইন',
      'sign_up': 'নিবন্ধন',

      // Login
      'welcome_back': 'আবার স্বাগতম!',
      'sign_in_subtitle': 'আপনার SupplyLink অ্যাকাউন্টে প্রবেশ করুন',
      'email_or_phone': 'ইমেইল বা ফোন',
      'email_phone_hint': 'ইমেইল বা 01XXXXXXXXX লিখুন',
      'password': 'পাসওয়ার্ড',
      'password_hint': 'পাসওয়ার্ড লিখুন',
      'no_account': 'অ্যাকাউন্ট নেই?',
      'login_failed': 'লগইন ব্যর্থ হয়েছে',

      // Register
      'register_shop_title': 'দোকান মালিকের অ্যাকাউন্ট তৈরি করুন',
      'register_shop_sub': 'শুরু করতে আপনার তথ্য দিন',
      'register_stock_title': 'সরবরাহকারীর অ্যাকাউন্ট তৈরি করুন',
      'register_stock_sub': 'শুরু করতে আপনার তথ্য দিন',
      'full_name': 'পুরো নাম',
      'name_hint': 'আপনার পুরো নাম',
      'phone_number': 'ফোন নম্বর',
      'phone_hint': '01XXXXXXXXX',
      'email': 'ইমেইল (ঐচ্ছিক)',
      'email_hint': 'your@email.com',
      'shop_name': 'দোকানের নাম',
      'shop_name_hint': 'দোকানের নাম লিখুন',
      'shop_category': 'দোকানের ধরন',
      'select_category': 'ধরন বেছে নিন',
      'company_name': 'প্রতিষ্ঠানের নাম',
      'company_hint': 'আপনার প্রতিষ্ঠানের নাম লিখুন',
      'product_categories': 'পণ্যের ধরন',
      'select_categories': 'আপনি কী সরবরাহ করেন তা বেছে নিন',
      'create_account': 'অ্যাকাউন্ট তৈরি করুন',
      'already_have_account': 'ইতিমধ্যে অ্যাকাউন্ট আছে?',
      'min_6_chars': 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে',
      'confirm_password': 'পাসওয়ার্ড নিশ্চিত করুন',
      'passwords_no_match': 'পাসওয়ার্ড মিলছে না',

      // Shop Owner Dashboard
      'dashboard': 'ড্যাশবোর্ড',
      'good_morning': 'শুভ সকাল',
      'good_afternoon': 'শুভ অপরাহ্ন',
      'good_evening': 'শুভ সন্ধ্যা',
      'open_demands': 'খোলা চাহিদা',
      'active_orders': 'সক্রিয় অর্ডার',
      'matched_demands': 'মিলেছে',
      'post_demand': 'চাহিদা দিন',
      'my_orders': 'আমার অর্ডার',
      'my_demands': 'আমার চাহিদা',
      'browse_stock': 'স্টক দেখুন',
      'quick_actions': 'দ্রুত কাজ',
      'recent_demands': 'সাম্প্রতিক চাহিদা',
      'recent_orders': 'সাম্প্রতিক অর্ডার',
      'unrated_orders': 'রেটিং দিন',
      'view_all': 'সব দেখুন',
      'notifications': 'নোটিফিকেশন',
      'profile': 'প্রোফাইল',
      'logout': 'লগআউট',
      'logout_confirm': 'আপনি কি লগআউট করতে চান?',

      // Post Demand
      'post_demand_title': 'চাহিদা দিন',
      'select_product_cat': 'পণ্যের ধরন বেছে নিন',
      'select_product': 'পণ্য বেছে নিন',
      'select_variant': 'ধরন বেছে নিন',
      'quantity': 'পরিমাণ',
      'quantity_hint': 'পরিমাণ লিখুন',
      'unit': 'একক',
      'notes': 'অতিরিক্ত নোট',
      'notes_hint': 'বিশেষ প্রয়োজনীয়তা...',
      'location': 'অবস্থান',
      'detect_location': 'আমার অবস্থান খুঁজুন',
      'pick_on_map': 'মানচিত্রে বেছে নিন',
      'post_demand_btn': 'চাহিদা পোস্ট করুন',
      'next_btn': 'পরবর্তী',
      'demand_posted': 'চাহিদা সফলভাবে পোস্ট হয়েছে!',

      // Matching Suppliers
      'matching_suppliers': 'কাছের সরবরাহকারী',
      'no_matches': 'কাছাকাছি কোন সরবরাহকারী পাওয়া যায়নি',
      'km_away': 'কি.মি. দূরে',
      'per': 'প্রতি',
      'available': 'মজুদ',
      'order_now': 'অর্ডার করুন',
      'sort_distance': 'কাছের',
      'sort_price': 'সস্তা',

      // Order Confirm
      'order_summary': 'অর্ডারের বিবরণ',
      'delivery_address': 'ডেলিভারি ঠিকানা',
      'delivery_hint': 'পুরো ডেলিভারি ঠিকানা লিখুন',
      'total_price': 'মোট মূল্য',
      'place_order': 'অর্ডার দিন',
      'order_placed': 'অর্ডার সফলভাবে দেওয়া হয়েছে!',
      'supplier': 'সরবরাহকারী',
      'product': 'পণ্য',
      'price_per_unit': 'একক মূল্য',

      // Order Status
      'order_status': 'অর্ডারের অবস্থা',
      'order_id': 'অর্ডার আইডি',
      'order_details': 'অর্ডারের বিবরণ',
      'generate_otp': 'OTP তৈরি করুন',
      'otp_generated': 'OTP তৈরি হয়েছে!',
      'your_otp': 'আপনার OTP কোড',
      'otp_expires': '১০ মিনিটে মেয়াদ শেষ',
      'show_otp_to_delivery': 'এই কোডটি ডেলিভারি ব্যক্তিকে দেখান',

      // My Orders
      'my_orders_title': 'আমার অর্ডার',
      'no_orders': 'এখনো কোন অর্ডার নেই',
      'rate_supplier': 'রেটিং দিন',
      'rating_completed': 'রেটিং দেওয়া হয়েছে',
      'tap_for_status': 'অবস্থা দেখতে ট্যাপ করুন',

      // Rate Supplier
      'rate_title': 'সরবরাহকারীকে রেটিং দিন',
      'your_rating': 'আপনার রেটিং',
      'tap_star': 'রেটিং দিতে স্টারে ট্যাপ করুন',
      'write_review': 'রিভিউ লিখুন (ঐচ্ছিক)',
      'review_hint': 'আপনার অভিজ্ঞতা শেয়ার করুন...',
      'submit_rating': 'রেটিং জমা দিন',
      'rating_submitted': 'রেটিং জমা হয়েছে!',
      'select_rating': 'রেটিং বেছে নিন',

      // My Demands
      'my_demands_title': 'আমার চাহিদা',
      'no_demands': 'এখনো কোন চাহিদা নেই',
      'cancel_demand': 'বাতিল',
      'demand_cancelled': 'চাহিদা বাতিল হয়েছে',
      'view_matches': 'মিলে যাওয়া দেখুন',
      'post_first_demand': 'প্রথম চাহিদা দিন',

      // Browse Stock
      'browse_stocks': 'স্টক দেখুন',
      'search_hint': 'পণ্য খুঁজুন...',
      'filter': 'ফিল্টার',
      'no_stocks': 'কোন স্টক পাওয়া যায়নি',
      'in_stock': 'মজুদ আছে',
      'sold_out': 'শেষ হয়ে গেছে',

      // Stockholder Dashboard
      'stock_dashboard': 'সরবরাহকারী ড্যাশবোর্ড',
      'active_stock': 'সক্রিয় স্টক',
      'new_orders': 'নতুন অর্ডার',
      'delivered_orders': 'ডেলিভারি হয়েছে',
      'post_stock': 'স্টক দিন',
      'my_stock': 'আমার স্টক',
      'order_inbox': 'অর্ডার ইনবক্স',
      'nearby_demands': 'কাছের চাহিদা',
      'earnings': 'আয়',

      // Post Stock
      'post_stock_title': 'স্টক পোস্ট করুন',
      'price_hint': 'মূল্য লিখুন',
      'warehouse_area': 'গুদামের এলাকা',
      'stock_posted': 'স্টক সফলভাবে পোস্ট হয়েছে!',
      'additional_notes': 'অতিরিক্ত নোট',

      // My Stock
      'my_stock_title': 'আমার স্টক',
      'no_stock': 'এখনো কোন স্টক নেই',
      'edit_stock': 'স্টক সম্পাদনা',
      'delete_stock': 'স্টক মুছুন',
      'delete_confirm': 'এই স্টক মুছে ফেলবেন?',
      'qty_available': 'মজুদ',
      'update_stock': 'স্টক আপডেট করুন',
      'stock_updated': 'স্টক আপডেট হয়েছে!',

      // Order Inbox
      'order_inbox_title': 'অর্ডার ইনবক্স',
      'no_incoming': 'কোন নতুন অর্ডার নেই',
      'accept': 'গ্রহণ করুন',
      'decline': 'বাতিল করুন',
      'mark_out_for_delivery': 'ডেলিভারিতে পাঠান',
      'verify_otp_btn': 'OTP যাচাই করুন',
      'location_hidden': 'গ্রহণের পর ঠিকানা দেখা যাবে',
      'order_accepted': 'অর্ডার গৃহীত হয়েছে!',
      'order_declined': 'অর্ডার বাতিল হয়েছে',
      'shop': 'দোকান',
      'area': 'এলাকা',

      // Verify OTP
      'verify_otp_title': 'ডেলিভারি OTP যাচাই',
      'enter_otp': 'OTP লিখুন',
      'otp_hint': '৬ সংখ্যার কোড',
      'verify_otp': 'ডেলিভারি নিশ্চিত করুন',
      'otp_verified': 'ডেলিভারি নিশ্চিত হয়েছে!',
      'invalid_otp': 'OTP ভুল বা মেয়াদ শেষ',

      // Nearby Demands
      'nearby_demands_title': 'কাছের চাহিদা',
      'no_nearby': 'কাছে কোন চাহিদা পাওয়া যায়নি',
      'wants': 'চাই',
      'demand_posted_at': 'পোস্ট করা হয়েছে',

      // Earnings
      'earnings_title': 'আয়',
      'total_earned': 'মোট আয়',
      'this_month': 'এই মাসে',
      'last_month': 'গত মাসে',
      'platform_fee': 'প্ল্যাটফর্ম চার্জ (২%)',
      'net_earnings': 'নিট আয়',
      'gross': 'মোট',
      'monthly_breakdown': 'মাসিক বিবরণ',
      'recent_transactions': 'সাম্প্রতিক লেনদেন',
      'no_earnings': 'এখনো কোন আয় নেই',

      // Notifications
      'notifications_title': 'নোটিফিকেশন',
      'no_notifications': 'এখনো কোন নোটিফিকেশন নেই',
      'mark_all_read': 'সব পড়া হিসেবে চিহ্নিত করুন',
      'could_not_load': 'নোটিফিকেশন লোড করা যায়নি',
      'unread': 'অপঠিত',

      // Profile
      'profile_title': 'প্রোফাইল',
      'edit_profile': 'প্রোফাইল সম্পাদনা',
      'verified': 'যাচাইকৃত',
      'not_verified': 'যাচাই হয়নি',
      'member_since': 'সদস্য হয়েছেন',
      'rating_avg': 'গড় রেটিং',
      'total_orders': 'মোট অর্ডার',
      'district': 'জেলা',
      'address': 'ঠিকানা',
      'update_profile': 'প্রোফাইল আপডেট করুন',
      'profile_updated': 'প্রোফাইল আপডেট হয়েছে!',

      // Auth register extended
      'fill_all_fields_category': 'সব তথ্য পূরণ করুন এবং কমপক্ষে একটি ক্যাটাগরি বেছে নিন',
      'shop_owner_signup': 'দোকান মালিকের নিবন্ধন',
      'create_account_subtitle': 'শুরু করতে অ্যাকাউন্ট তৈরি করুন',
      'what_do_you_sell': 'আপনি কী বিক্রি করেন?',
      'password_min_length': 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে',
      'cannot_connect': 'সার্ভারে সংযোগ হচ্ছে না',
      'stockholder_signup': 'স্টকহোল্ডার নিবন্ধন',
      'join_as_supplier': 'SupplyLink-এ সরবরাহকারী হিসেবে যোগ দিন',
      'what_do_you_supply': 'আপনি কী সরবরাহ করেন?',
      'select_all_apply': 'যা প্রযোজ্য সব বেছে নিন',

      // Shop owner dashboard extended
      'active_demands': 'সক্রিয় চাহিদা',
      'see_all': 'সব দেখুন',
      'post_demand_action': 'চাহিদা\nদিন',
      'browse_stocks_action': 'স্টক\nদেখুন',
      'my_orders_action': 'আমার\nঅর্ডার',
      'post_new_demand': 'নতুন\nচাহিদা',
      'log_out_title': 'লগআউট?',
      'log_out_subtitle': 'আবার সাইন ইন করতে হবে।',
      'log_out': 'লগআউট',
      'nav_home': 'হোম',
      'nav_demands': 'চাহিদা',
      'nav_orders': 'অর্ডার',
      'nav_profile': 'প্রোফাইল',
      'nav_my_stock': 'আমার স্টক',

      // Post demand extended
      'post_a_demand': 'চাহিদা দিন',
      'suppliers_respond_subtitle': 'কাছের সরবরাহকারীরা তাৎক্ষণিক সাড়া দেন',
      'search_products_hint': 'পণ্য খুঁজুন...',

      // My orders extended
      'my_orders_subtitle': 'সব অর্ডার ট্র্যাক করুন',
      'filter_all': 'সব',
      'status_pending': 'অপেক্ষায়',
      'status_accepted': 'গৃহীত',
      'status_on_way': 'পথে আছে',
      'status_delivered': 'পৌঁছে গেছে',
      'rate_supplier_btn': 'সরবরাহকারীকে রেটিং দিন',
      'no_orders_yet': 'এখনো কোন অর্ডার নেই',
      'no_orders_subtitle': 'প্রথম অর্ডার দিন',

      // My demands extended
      'my_demands_subtitle': 'সক্রিয় চাহিদা ট্র্যাক করুন',
      'new_demand_fab': 'নতুন চাহিদা',
      'no_demands_yet': 'এখনো কোন চাহিদা নেই',
      'no_demands_subtitle': 'প্রথম চাহিদা দিয়ে সরবরাহকারী খুঁজুন',
      'no_demands_filter': 'এই স্ট্যাটাসে কোন চাহিদা নেই',

      // Matching suppliers extended
      'nearby_suppliers': 'কাছের সরবরাহকারী',
      'search_supplier_hint': 'সরবরাহকারী বা এলাকা খুঁজুন...',
      'sort_nearest': 'কাছের',
      'sort_cheapest': 'সস্তা',
      'sort_top_rated': 'শীর্ষ রেটেড',
      'no_suppliers_found': 'কোন সরবরাহকারী পাওয়া যায়নি',
      'no_suppliers_subtitle': 'সার্চ বা ফিল্টার পরিবর্তন করুন',
      'refresh_btn': 'রিফ্রেশ',

      // Order confirm extended
      'confirm_order': 'অর্ডার নিশ্চিত করুন',
      'review_place_order': 'অর্ডার পর্যালোচনা করুন',
      'delivery_location': 'ডেলিভারির স্থান',

      // Order status extended
      'order_status_title': 'অর্ডারের অবস্থা',
      'otp_valid_for': '১০ মিনিটের জন্য বৈধ',
      'generate_new_code': 'নতুন কোড তৈরি করুন',
      'delivery_progress': 'ডেলিভারির অগ্রগতি',

      // Rate supplier extended
      'rate_supplier_title': 'সরবরাহকারীকে রেটিং দিন',
      'rate_supplier_subtitle': 'ডেলিভারির অভিজ্ঞতা শেয়ার করুন',
      'submit_review': 'রিভিউ জমা দিন',

      // Browse stocks extended
      'browse_stocks_title': 'স্টক দেখুন',
      'search_stocks_hint': 'চাল, তেল, রং, সরবরাহকারী খুঁজুন...',
      'no_stocks_found': 'কোন স্টক পাওয়া যায়নি',

      // Stockholder dashboard extended
      'orders_action': 'অর্ডার',
      'post_stock_action': 'স্টক\nদিন',
      'my_stock_action': 'আমার\nস্টক',
      'nearby_demands_action': 'কাছের\nচাহিদা',
      'accept_btn': 'গ্রহণ',
      'decline_btn': 'বাতিল',

      // Post stock extended
      'post_stock_btn': 'স্টক পোস্ট করুন',

      // My stock extended
      'no_stock_yet': 'এখনো কোন স্টক নেই',
      'delete_stock_title': 'এই স্টক মুছে ফেলবেন?',

      // Order inbox extended
      'order_inbox_subtitle': 'আসা অর্ডার পরিচালনা করুন',

      // Order detail extended
      'decline_order_title': 'অর্ডার বাতিল করবেন?',
      'buyer_info_hidden': 'গ্রহণের পর ক্রেতার তথ্য দেখা যাবে',
      'confirm_delivery_btn': 'ডেলিভারি নিশ্চিত করুন',
      'accept_order_btn': 'অর্ডার গ্রহণ করুন',
      'mark_out_delivery': 'ডেলিভারিতে পাঠান',

      // Verify OTP extended
      'delivered_title': 'পৌঁছে গেছে!',
      'otp_verified_message': 'OTP যাচাই হয়েছে। অর্ডার সফলভাবে ডেলিভারি হয়েছে।',
      'done_btn': 'সম্পন্ন',
      'enter_otp_subtitle': 'দোকান মালিকের OTP লিখুন',
      'enter_6digit_otp': '৬ সংখ্যার OTP লিখুন',
      'ask_shop_owner_otp': 'ডেলিভারির OTP কোডের জন্য দোকান মালিককে জিজ্ঞেস করুন',

      // Nearby demands extended
      'nearby_demands_subtitle': '১০ কিমির মধ্যে খোলা চাহিদা',
      'no_demands_category': 'এই ক্যাটাগরিতে কোন চাহিদা নেই',

      // Earnings extended
      'my_earnings_title': 'আমার আয়',
      'earnings_subtitle': '২% প্ল্যাটফর্ম চার্জের পর নিট',
      'total_net_earnings': 'মোট নিট আয়',
      'net_earnings_label': 'নিট আয়',
      'this_month_label': 'এই মাসে',
      'last_month_label': 'গত মাসে',
      'could_not_load_earnings': 'আয় লোড করা যায়নি',
      'retry_btn': 'আবার চেষ্টা করুন',

      // Notifications extended
      'could_not_load_notifications': 'নোটিফিকেশন লোড করা যায়নি',

      // Profile extended
      'verified_badge': 'যাচাইকৃত',
      'edit_profile_btn': 'প্রোফাইল সম্পাদনা',

      // Edit profile extended
      'edit_profile_title': 'প্রোফাইল সম্পাদনা',
      'edit_profile_subtitle': 'আপনার তথ্য আপডেট করুন',
      'save_changes_btn': 'পরিবর্তন সংরক্ষণ করুন',
    },
  };
}
