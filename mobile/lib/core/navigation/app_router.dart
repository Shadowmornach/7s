import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/coordinators/session_coordinator.dart';
import '../../features/auth/presentation/screens/splash_session_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_flow_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/passenger/presentation/screens/passenger_home_screen.dart';
import '../../features/passenger/presentation/screens/destination_search_screen.dart';
import '../../features/passenger/presentation/screens/fare_offer_screen.dart';
import '../../features/passenger/presentation/screens/searching_driver_screen.dart';
import '../../features/passenger/presentation/screens/driver_en_route_screen.dart';
import '../../features/passenger/presentation/screens/ride_completed_screen.dart';
import '../../features/rider/presentation/screens/rider_home_screen.dart';
import '../../features/settings/presentation/screens/profile_settings_screen.dart';
import '../../features/settings/presentation/screens/saved_places_screen.dart';
import '../../features/safety/presentation/screens/safety_center_screen.dart';
import '../../features/safety/presentation/screens/emergency_contacts_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/permissions_education_screen.dart';
import '../../features/onboarding/presentation/screens/help_center_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/passenger/presentation/screens/schedule_ride_screen.dart';
import '../../features/passenger/presentation/screens/driver_chat_screen.dart';
import '../../features/legal/presentation/screens/terms_of_service_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';

class AppRouter {
  static GoRouter buildRouter(AuthNotifier authNotifier) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authNotifier,
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authNotifier.state;
        final session = authNotifier.currentSession;

        final isAuthScreen = state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/sign-in' ||
            state.matchedLocation == '/sign-up' ||
            state.matchedLocation == '/forgot-password' ||
            state.matchedLocation == '/login';
        final isSplash = state.matchedLocation == '/splash';
        final isCompleteProfile = state.matchedLocation == '/complete-profile';

        final isOnboarding = state.matchedLocation == '/onboarding' ||
            state.matchedLocation == '/permissions-explain' ||
            state.matchedLocation == '/help-center' ||
            state.matchedLocation == '/terms' ||
            state.matchedLocation == '/privacy-policy';

        if (isOnboarding) return null;

        if (authState == AuthState.restoring) {
          return isSplash ? null : '/splash';
        }

        if (authState == AuthState.unauthenticated ||
            authState == AuthState.expired ||
            authState == AuthState.failed ||
            session == null) {
          return isAuthScreen ? null : '/welcome';
        }

        if (authState == AuthState.authenticated) {
          if (!session.isProfileComplete) {
            return isCompleteProfile ? null : '/complete-profile';
          }
          if (isAuthScreen || isSplash) {
            return '/passenger/home';
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
          path: '/welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/sign-in',
          builder: (context, state) => const SignInScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const SignInScreen(),
        ),
        GoRoute(
          path: '/sign-up',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordFlowScreen(),
        ),
        GoRoute(
          path: '/complete-profile',
          builder: (context, state) => const CompleteProfileScreen(),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsOfServiceScreen(),
        ),
        GoRoute(
          path: '/privacy-policy',
          builder: (context, state) => const PrivacyPolicyScreen(),
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
          path: '/passenger/fare-offer',
          builder: (context, state) => const FareOfferScreen(),
        ),
        GoRoute(
          path: '/passenger/searching-driver',
          builder: (context, state) => const SearchingDriverScreen(),
        ),
        GoRoute(
          path: '/passenger/driver-en-route',
          builder: (context, state) => const DriverEnRouteScreen(),
        ),
        GoRoute(
          path: '/passenger/ride-completed',
          builder: (context, state) => const RideCompletedScreen(),
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
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/permissions-explain',
          builder: (context, state) => const PermissionsEducationScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/passenger/schedule',
          builder: (context, state) => const ScheduleRideScreen(),
        ),
        GoRoute(
          path: '/driver-chat',
          builder: (context, state) => const DriverChatScreen(),
        ),
        GoRoute(
          path: '/help-center',
          builder: (context, state) => const HelpCenterScreen(),
        ),
      ],
    );
  }
}


