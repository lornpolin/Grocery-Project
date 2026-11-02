import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'main_shell.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/all_products_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_details_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/addresses/screens/addresses_screen.dart';
import '../../features/product_details/screens/product_details_screen.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../providers/app_providers.dart';
import '../auth/auth_state.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable: AuthState.instance,
  redirect: (context, state) {
    final signedIn = AuthState.instance.value;
    final path = state.uri.path;
    const authPaths = ['/sign-in', '/sign-up'];
    const openPaths = ['/splash', '/onboarding', ...authPaths];
    if (!signedIn && !openPaths.contains(path)) return '/sign-in';
    if (signedIn && authPaths.contains(path)) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    // Full-screen order flow (shown above the tab bar).
    GoRoute(
      path: '/cart',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/favorites',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/addresses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddressesScreen(),
    ),
    GoRoute(
      path: '/products',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AllProductsScreen(
        initialCategoryId: state.uri.queryParameters['category'],
      ),
    ),
    GoRoute(
      path: '/order-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        Order? order = state.extra is Order ? state.extra as Order : null;
        final id = state.uri.queryParameters['id'];
        if (order == null && id != null) {
          final orders = ProviderScope.containerOf(
            context,
            listen: false,
          ).read(ordersProvider);
          for (final o in orders) {
            if (o.id == id) {
              order = o;
              break;
            }
          }
        }
        if (order == null) return const OrdersScreen();
        return OrderDetailsScreen(initialOrder: order);
      },
    ),
    GoRoute(
      path: '/product-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        Product? product =
            state.extra is Product ? state.extra as Product : null;
        final id = state.uri.queryParameters['id'];
        if (product == null && id != null) {
          final products =
              ProviderScope.containerOf(context, listen: false).read(productsProvider);
          for (final p in products) {
            if (p.id == id) product = p;
          }
        }
        if (product == null) return const HomeScreen();
        return ProductDetailsScreen(product: product);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrdersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              builder: (context, state) => CategoriesScreen(
                initialCategoryId: state.uri.queryParameters['id'],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
