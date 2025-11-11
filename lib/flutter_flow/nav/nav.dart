import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

import '/backend/supabase/supabase.dart';

import '/auth/base_auth_user_provider.dart';

import '/backend/push_notifications/push_notifications_handler.dart'
    show PushNotificationsHandler;
import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? HomePageWidget() : SplashScreenWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? HomePageWidget()
              : SplashScreenWidget(),
        ),
        FFRoute(
          name: ProviderConfirmationPageWidget.routeName,
          path: ProviderConfirmationPageWidget.routePath,
          builder: (context, params) => ProviderConfirmationPageWidget(),
        ),
        FFRoute(
          name: VideoCallWidget.routeName,
          path: VideoCallWidget.routePath,
          builder: (context, params) => VideoCallWidget(),
        ),
        FFRoute(
          name: JoinCallWidget.routeName,
          path: JoinCallWidget.routePath,
          builder: (context, params) => JoinCallWidget(),
        ),
        FFRoute(
          name: ProviderLandingPageWidget.routeName,
          path: ProviderLandingPageWidget.routePath,
          builder: (context, params) => ProviderLandingPageWidget(),
        ),
        FFRoute(
          name: RolePageWidget.routeName,
          path: RolePageWidget.routePath,
          builder: (context, params) => RolePageWidget(),
        ),
        FFRoute(
          name: PatientAccountCreationWidget.routeName,
          path: PatientAccountCreationWidget.routePath,
          builder: (context, params) => PatientAccountCreationWidget(),
        ),
        FFRoute(
          name: SystemAdminLandingPageWidget.routeName,
          path: SystemAdminLandingPageWidget.routePath,
          builder: (context, params) => SystemAdminLandingPageWidget(),
        ),
        FFRoute(
          name: FacilityAdminLandingPageWidget.routeName,
          path: FacilityAdminLandingPageWidget.routePath,
          builder: (context, params) => FacilityAdminLandingPageWidget(),
        ),
        FFRoute(
          name: PatientProfilePageWidget.routeName,
          path: PatientProfilePageWidget.routePath,
          builder: (context, params) => PatientProfilePageWidget(
            patientAuthUser: params.getParam(
              'patientAuthUser',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: HomePageWidget.routeName,
          path: HomePageWidget.routePath,
          builder: (context, params) => HomePageWidget(),
        ),
        FFRoute(
          name: FeaturesWidget.routeName,
          path: FeaturesWidget.routePath,
          builder: (context, params) => FeaturesWidget(),
        ),
        FFRoute(
          name: AboutUsWidget.routeName,
          path: AboutUsWidget.routePath,
          builder: (context, params) => AboutUsWidget(),
        ),
        FFRoute(
          name: SplashScreenWidget.routeName,
          path: SplashScreenWidget.routePath,
          builder: (context, params) => SplashScreenWidget(),
        ),
        FFRoute(
          name: PublicationsWidget.routeName,
          path: PublicationsWidget.routePath,
          builder: (context, params) => PublicationsWidget(),
        ),
        FFRoute(
          name: FacilityStatusPageWidget.routeName,
          path: FacilityStatusPageWidget.routePath,
          builder: (context, params) => FacilityStatusPageWidget(),
        ),
        FFRoute(
          name: SystemAdminAccountCreationWidget.routeName,
          path: SystemAdminAccountCreationWidget.routePath,
          builder: (context, params) => SystemAdminAccountCreationWidget(),
        ),
        FFRoute(
          name: FacilityAdminAccountCreationWidget.routeName,
          path: FacilityAdminAccountCreationWidget.routePath,
          builder: (context, params) => FacilityAdminAccountCreationWidget(),
        ),
        FFRoute(
          name: AdminPatientStatusPageWidget.routeName,
          path: AdminPatientStatusPageWidget.routePath,
          builder: (context, params) => AdminPatientStatusPageWidget(),
        ),
        FFRoute(
          name: AppoitmentStatusPageWidget.routeName,
          path: AppoitmentStatusPageWidget.routePath,
          builder: (context, params) => AppoitmentStatusPageWidget(),
        ),
        FFRoute(
          name: ProviderStatusPageWidget.routeName,
          path: ProviderStatusPageWidget.routePath,
          builder: (context, params) => ProviderStatusPageWidget(),
        ),
        FFRoute(
          name: PaymentStatusPageWidget.routeName,
          path: PaymentStatusPageWidget.routePath,
          builder: (context, params) => PaymentStatusPageWidget(),
        ),
        FFRoute(
          name: FacilityDetailsPageWidget.routeName,
          path: FacilityDetailsPageWidget.routePath,
          builder: (context, params) => FacilityDetailsPageWidget(),
        ),
        FFRoute(
          name: PatientLandingPageWidget.routeName,
          path: PatientLandingPageWidget.routePath,
          builder: (context, params) => PatientLandingPageWidget(),
        ),
        FFRoute(
          name: AppointmentsWidget.routeName,
          path: AppointmentsWidget.routePath,
          builder: (context, params) => AppointmentsWidget(
            username: params.getParam(
              'username',
              ParamType.String,
            ),
            usernumber: params.getParam(
              'usernumber',
              ParamType.String,
            ),
            avatarUrl: params.getParam(
              'avatarUrl',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: FacilityRegistrationPageWidget.routeName,
          path: FacilityRegistrationPageWidget.routePath,
          builder: (context, params) => FacilityRegistrationPageWidget(
            departmentsChosen: params.getParam(
              'departmentsChosen',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AdminStatusPageWidget.routeName,
          path: AdminStatusPageWidget.routePath,
          builder: (context, params) => AdminStatusPageWidget(),
        ),
        FFRoute(
          name: TermsAndCOnditionsPageWidget.routeName,
          path: TermsAndCOnditionsPageWidget.routePath,
          builder: (context, params) => TermsAndCOnditionsPageWidget(),
        ),
        FFRoute(
          name: PaymentHistoryWidget.routeName,
          path: PaymentHistoryWidget.routePath,
          requireAuth: true,
          builder: (context, params) => PaymentHistoryWidget(
            username: params.getParam(
              'username',
              ParamType.String,
            ),
            userNumber: params.getParam(
              'userNumber',
              ParamType.String,
            ),
            avatar: params.getParam(
              'avatar',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: MedicalPractitionersWidget.routeName,
          path: MedicalPractitionersWidget.routePath,
          requireAuth: true,
          builder: (context, params) => MedicalPractitionersWidget(),
        ),
        FFRoute(
          name: PractionerDetailWidget.routeName,
          path: PractionerDetailWidget.routePath,
          builder: (context, params) => PractionerDetailWidget(
            providerid: params.getParam(
              'providerid',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: FacilitySearchPageWidget.routeName,
          path: FacilitySearchPageWidget.routePath,
          builder: (context, params) => FacilitySearchPageWidget(),
        ),
        FFRoute(
          name: PatientsNotificationsPageWidget.routeName,
          path: PatientsNotificationsPageWidget.routePath,
          builder: (context, params) => PatientsNotificationsPageWidget(),
        ),
        FFRoute(
          name: ProviderProfilePageWidget.routeName,
          path: ProviderProfilePageWidget.routePath,
          builder: (context, params) => ProviderProfilePageWidget(),
        ),
        FFRoute(
          name: PatientsMedicationPageWidget.routeName,
          path: PatientsMedicationPageWidget.routePath,
          builder: (context, params) => PatientsMedicationPageWidget(),
        ),
        FFRoute(
          name: PatientDiagnosticsWidget.routeName,
          path: PatientDiagnosticsWidget.routePath,
          builder: (context, params) => PatientDiagnosticsWidget(),
        ),
        FFRoute(
          name: AdminPatientsAdminEditPageWidget.routeName,
          path: AdminPatientsAdminEditPageWidget.routePath,
          builder: (context, params) => AdminPatientsAdminEditPageWidget(),
        ),
        FFRoute(
          name: FacilitySettingsPageWidget.routeName,
          path: FacilitySettingsPageWidget.routePath,
          builder: (context, params) => FacilitySettingsPageWidget(),
        ),
        FFRoute(
          name: SignInWidget.routeName,
          path: SignInWidget.routePath,
          builder: (context, params) => SignInWidget(),
        ),
        FFRoute(
          name: PatientsSettingsPageWidget.routeName,
          path: PatientsSettingsPageWidget.routePath,
          builder: (context, params) => PatientsSettingsPageWidget(),
        ),
        FFRoute(
          name: FacilityAdminSettingsPageWidget.routeName,
          path: FacilityAdminSettingsPageWidget.routePath,
          builder: (context, params) => FacilityAdminSettingsPageWidget(),
        ),
        FFRoute(
          name: ProviderSettingsPageWidget.routeName,
          path: ProviderSettingsPageWidget.routePath,
          builder: (context, params) => ProviderSettingsPageWidget(),
        ),
        FFRoute(
          name: SystemAdminSettingsPageWidget.routeName,
          path: SystemAdminSettingsPageWidget.routePath,
          builder: (context, params) => SystemAdminSettingsPageWidget(),
        ),
        FFRoute(
          name: ProviderNotificationsPageWidget.routeName,
          path: ProviderNotificationsPageWidget.routePath,
          builder: (context, params) => ProviderNotificationsPageWidget(),
        ),
        FFRoute(
          name: FacilityNotificationsPageWidget.routeName,
          path: FacilityNotificationsPageWidget.routePath,
          builder: (context, params) => FacilityNotificationsPageWidget(),
        ),
        FFRoute(
          name: SystemAdminNotificationsPageWidget.routeName,
          path: SystemAdminNotificationsPageWidget.routePath,
          builder: (context, params) => SystemAdminNotificationsPageWidget(),
        ),
        FFRoute(
          name: SystemAdminProfilePageWidget.routeName,
          path: SystemAdminProfilePageWidget.routePath,
          builder: (context, params) => SystemAdminProfilePageWidget(
            patientAuthUser: params.getParam(
              'patientAuthUser',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: FacilityAdminProfilePageWidget.routeName,
          path: FacilityAdminProfilePageWidget.routePath,
          builder: (context, params) => FacilityAdminProfilePageWidget(
            patientAuthUser: params.getParam(
              'patientAuthUser',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ProvidersDocumentPageWidget.routeName,
          path: ProvidersDocumentPageWidget.routePath,
          builder: (context, params) => ProvidersDocumentPageWidget(),
        ),
        FFRoute(
          name: PatientsDocumentPageWidget.routeName,
          path: PatientsDocumentPageWidget.routePath,
          builder: (context, params) => PatientsDocumentPageWidget(),
        ),
        FFRoute(
          name: ProviderAccountCreationWidget.routeName,
          path: ProviderAccountCreationWidget.routePath,
          builder: (context, params) => ProviderAccountCreationWidget(
            eMCPhone: params.getParam(
              'eMCPhone',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: FacilityAdminDocumentPageWidget.routeName,
          path: FacilityAdminDocumentPageWidget.routePath,
          builder: (context, params) => FacilityAdminDocumentPageWidget(),
        ),
        FFRoute(
          name: SystAdminDocumentPageWidget.routeName,
          path: SystAdminDocumentPageWidget.routePath,
          builder: (context, params) => SystAdminDocumentPageWidget(),
        ),
        FFRoute(
          name: SystAdminPaymentPageWidget.routeName,
          path: SystAdminPaymentPageWidget.routePath,
          builder: (context, params) => SystAdminPaymentPageWidget(),
        ),
        FFRoute(
          name: FacilityAdminPaymentPageWidget.routeName,
          path: FacilityAdminPaymentPageWidget.routePath,
          builder: (context, params) => FacilityAdminPaymentPageWidget(),
        ),
        FFRoute(
          name: ProvidersWalletWidget.routeName,
          path: ProvidersWalletWidget.routePath,
          builder: (context, params) => ProvidersWalletWidget(),
        ),
        FFRoute(
          name: AvailabilityWidget.routeName,
          path: AvailabilityWidget.routePath,
          builder: (context, params) => AvailabilityWidget(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/splashScreen';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Container(
                  color: Colors.transparent,
                  child: Image.asset(
                    'assets/images/medzen.logo.png',
                    fit: BoxFit.contain,
                  ),
                )
              : PushNotificationsHandler(child: page);

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
