import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/coordinators/session_coordinator.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_session_screen.dart';
import '../../features/auth/domain/models/user_session.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/permissions_education_screen.dart';
import '../../features/onboarding/presentation/screens/help_center_screen.dart';
import '../../features/passenger/presentation/screens/passenger_home_screen.dart';
import '../../features/passenger/presentation/screens/destination_search_screen.dart';
import '../../features/rider/presentation/screens/rider_home_screen.dart';
import '../../features/settings/presentation/screens/profile_settings_screen.dart';
import '../../features/settings/presentation/screens/saved_places_screen.dart';
import '../../features/safety/presentation/screens/safety_center_screen.dart';
import '../../features/safety/presentation/screens/emergency_contacts_screen.dart';

class AppRouter {
  static GoRouter buildRouter(AuthNotifier authNotifier) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authNotifier,
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authNotifier.state;
        final isLoggingIn = state.matchedLocation == '/login';
        final isSplash = state.matchedLocation == '/splash';
        final isOnboarding = state.matchedLocation == '/onboarding' ||
            state.matchedLocation == '/permissions-explain' ||
            state.matchedLocation == '/help-center';

        if (isOnboarding) return null;

        if (authState == AuthState.restoring) {
          return isSplash ? null : '/splash';
        }

        if (authState == AuthState.unauthenticated ||
            authState == AuthState.expired ||
            authState == AuthState.failed) {
          return isLoggingIn ? null : '/login';
        }

        if (authState == AuthState.authenticated) {
          final role = authNotifier.currentSession?.role ?? UserRole.passenger;
          String targetRoute;
          switch (role) {
            case UserRole.rider:
              targetRoute = '/rider/home';
              break;
            case UserRole.owner:
              targetRoute = '/passenger/home';
              break;
            case UserRole.passenger:
              targetRoute = '/passenger/home';
              break;
          }

          if (isLoggingIn || isSplash) {
            return targetRoute;
          }
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashSessionScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/permissions-explain',
          builder: (context, state) => const PermissionsEducationScreen(),
        ),
        GoRoute(
          path: '/help-center',
          builder: (context, state) => const HelpCenterScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/passenger/home',
          builder: (context, state) => const PassengerHomeScreen(),
        ),
        GoRoute(
          path: '/passenger/search',
          builder: (context, state) => const DestinationSearchScreen(),
        ),
        GoRoute(
          path: '/rider/home',
          builder: (context, state) => const RiderHomeScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const ProfileSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/saved-places',
          builder: (context, state) => const SavedPlacesScreen(),
        ),
        GoRoute(
          path: '/safety',
          builder: (context, state) => const SafetyCenterScreen(),
        ),
        GoRoute(
          path: '/safety/contacts',
          builder: (context, state) => const EmergencyContactsScreen(),
        ),
      ],
    );
  }
}
