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
          appStateNotifier.loggedIn ? SignInWidget() : HomePageWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) =>
              appStateNotifier.loggedIn ? SignInWidget() : HomePageWidget(),
          routes: [
            FFRoute(
              name: ProviderConfirmationPageWidget.routeName,
              path: ProviderConfirmationPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ProviderConfirmationPageWidget(),
            ),
            FFRoute(
              name: RolePageWidget.routeName,
              path: RolePageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => RolePageWidget(),
            ),
            FFRoute(
              name: PatientAccountCreationWidget.routeName,
              path: PatientAccountCreationWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PatientAccountCreationWidget(),
            ),
            FFRoute(
              name: SystemAdminLandingPageWidget.routeName,
              path: SystemAdminLandingPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SystemAdminLandingPageWidget(),
            ),
            FFRoute(
              name: FacilityAdminLandingPageWidget.routeName,
              path: FacilityAdminLandingPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => FacilityAdminLandingPageWidget(),
            ),
            FFRoute(
              name: PatientProfilePageWidget.routeName,
              path: PatientProfilePageWidget.routePath,
              requireAuth: true,
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
              name: PublicationsWidget.routeName,
              path: PublicationsWidget.routePath,
              builder: (context, params) => PublicationsWidget(),
            ),
            FFRoute(
              name: SystemAdminAccountCreationWidget.routeName,
              path: SystemAdminAccountCreationWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SystemAdminAccountCreationWidget(),
            ),
            FFRoute(
              name: FacilityAdminAccountCreationWidget.routeName,
              path: FacilityAdminAccountCreationWidget.routePath,
              requireAuth: true,
              builder: (context, params) =>
                  FacilityAdminAccountCreationWidget(),
            ),
            FFRoute(
              name: PatientLandingPageWidget.routeName,
              path: PatientLandingPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PatientLandingPageWidget(),
            ),
            FFRoute(
              name: AppointmentsWidget.routeName,
              path: AppointmentsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AppointmentsWidget(
                facilityid: params.getParam(
                  'facilityid',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: CareCenterRegistrationPageWidget.routeName,
              path: CareCenterRegistrationPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CareCenterRegistrationPageWidget(
                departmentsChosen: params.getParam(
                  'departmentsChosen',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: AdminStatusPageWidget.routeName,
              path: AdminStatusPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AdminStatusPageWidget(),
            ),
            FFRoute(
              name: PaymentHistoryWidget.routeName,
              path: PaymentHistoryWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PaymentHistoryWidget(
                facilityid: params.getParam(
                  'facilityid',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: MedicalPractitionersWidget.routeName,
              path: MedicalPractitionersWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MedicalPractitionersWidget(
                gender: params.getParam(
                  'gender',
                  ParamType.String,
                ),
                specialty: params.getParam(
                  'specialty',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: PractionerDetailWidget.routeName,
              path: PractionerDetailWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PractionerDetailWidget(
                providerid: params.getParam(
                  'providerid',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: CareCenterSearchPageWidget.routeName,
              path: CareCenterSearchPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CareCenterSearchPageWidget(),
            ),
            FFRoute(
              name: ProviderProfilePageWidget.routeName,
              path: ProviderProfilePageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ProviderProfilePageWidget(),
            ),
            FFRoute(
              name: PatientsMedicationPageWidget.routeName,
              path: PatientsMedicationPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PatientsMedicationPageWidget(),
            ),
            FFRoute(
              name: PatientDiagnosticsWidget.routeName,
              path: PatientDiagnosticsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PatientDiagnosticsWidget(),
            ),
            FFRoute(
              name: SignInWidget.routeName,
              path: SignInWidget.routePath,
              builder: (context, params) => SignInWidget(),
            ),
            FFRoute(
              name: PatientsSettingsPageWidget.routeName,
              path: PatientsSettingsPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PatientsSettingsPageWidget(),
            ),
            FFRoute(
              name: FacilityAdminSettingsPageWidget.routeName,
              path: FacilityAdminSettingsPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => FacilityAdminSettingsPageWidget(),
            ),
            FFRoute(
              name: ProviderSettingsPageWidget.routeName,
              path: ProviderSettingsPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ProviderSettingsPageWidget(),
            ),
            FFRoute(
              name: SystemAdminSettingsPageWidget.routeName,
              path: SystemAdminSettingsPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SystemAdminSettingsPageWidget(),
            ),
            FFRoute(
              name: SystemAdminProfilePageWidget.routeName,
              path: SystemAdminProfilePageWidget.routePath,
              requireAuth: true,
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
              requireAuth: true,
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
              requireAuth: true,
              builder: (context, params) => ProvidersDocumentPageWidget(),
            ),
            FFRoute(
              name: PatientsDocumentPageWidget.routeName,
              path: PatientsDocumentPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PatientsDocumentPageWidget(),
            ),
            FFRoute(
              name: ProviderAccountCreationWidget.routeName,
              path: ProviderAccountCreationWidget.routePath,
              requireAuth: true,
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
              requireAuth: true,
              builder: (context, params) => FacilityAdminDocumentPageWidget(),
            ),
            FFRoute(
              name: CareCentersTypesWidget.routeName,
              path: CareCentersTypesWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CareCentersTypesWidget(),
            ),
            FFRoute(
              name: CareCentersWidget.routeName,
              path: CareCentersWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CareCentersWidget(
                facilitytype: params.getParam(
                  'facilitytype',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: CareCenterDetailsWidget.routeName,
              path: CareCenterDetailsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CareCenterDetailsWidget(
                facilityID: params.getParam(
                  'facilityID',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: ChatWidget.routeName,
              path: ChatWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ChatWidget(
                conversationId: params.getParam(
                  'conversationId',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: AIChatHistoryPageWidget.routeName,
              path: AIChatHistoryPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AIChatHistoryPageWidget(),
            ),
            FFRoute(
              name: AdminPatientsPageWidget.routeName,
              path: AdminPatientsPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AdminPatientsPageWidget(),
            ),
            FFRoute(
              name: ProviderLandingPageWidget.routeName,
              path: ProviderLandingPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ProviderLandingPageWidget(),
            ),
            FFRoute(
              name: CareCenterStatusPageWidget.routeName,
              path: CareCenterStatusPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CareCenterStatusPageWidget(
                facilityID: params.getParam(
                  'facilityID',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: AdminProviderStatusPageWidget.routeName,
              path: AdminProviderStatusPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AdminProviderStatusPageWidget(
                facilityID: params.getParam(
                  'facilityID',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: ResetPasswordFromLinkWidget.routeName,
              path: ResetPasswordFromLinkWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ResetPasswordFromLinkWidget(
                token: params.getParam(
                  'token',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: FinanceWidget.routeName,
              path: FinanceWidget.routePath,
              requireAuth: true,
              builder: (context, params) => FinanceWidget(),
            ),
            FFRoute(
              name: NotificationsWidget.routeName,
              path: NotificationsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => NotificationsWidget(),
            ),
            FFRoute(
              name: ProviderSummaryPageWidget.routeName,
              path: ProviderSummaryPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ProviderSummaryPageWidget(
                providerID: params.getParam(
                  'providerID',
                  ParamType.String,
                ),
                image: params.getParam(
                  'image',
                  ParamType.String,
                ),
                name: params.getParam(
                  'name',
                  ParamType.String,
                ),
                specialty: params.getParam(
                  'specialty',
                  ParamType.String,
                ),
                licenseNumb: params.getParam(
                  'licenseNumb',
                  ParamType.String,
                ),
                phone: params.getParam(
                  'phone',
                  ParamType.String,
                ),
                eMCName: params.getParam(
                  'eMCName',
                  ParamType.String,
                ),
                eMCRelationship: params.getParam(
                  'eMCRelationship',
                  ParamType.String,
                ),
                eMCPhone: params.getParam(
                  'eMCPhone',
                  ParamType.String,
                ),
                licenseExpiration: params.getParam(
                  'licenseExpiration',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: ChatHistoryPageWidget.routeName,
              path: ChatHistoryPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ChatHistoryPageWidget(
                userRole: params.getParam(
                  'userRole',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: ChatHistoryDetailWidget.routeName,
              path: ChatHistoryDetailWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ChatHistoryDetailWidget(
                appointmentID: params.getParam(
                  'appointmentID',
                  ParamType.String,
                ),
                appointmentDate: params.getParam(
                  'appointmentDate',
                  ParamType.DateTime,
                ),
                username: params.getParam(
                  'username',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: TermsAndConditionsWidget.routeName,
              path: TermsAndConditionsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => TermsAndConditionsWidget(),
            ),
            FFRoute(
              name: AboutUsPageWidget.routeName,
              path: AboutUsPageWidget.routePath,
              builder: (context, params) => AboutUsPageWidget(),
            ),
            FFRoute(
              name: FacilityadminPatientsPageWidget.routeName,
              path: FacilityadminPatientsPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => FacilityadminPatientsPageWidget(
                facilityID: params.getParam(
                  'facilityID',
                  ParamType.String,
                ),
              ),
            ),
            FFRoute(
              name: CareCenterSettingsPageWidget.routeName,
              path: CareCenterSettingsPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CareCenterSettingsPageWidget(
                facilityID: params.getParam(
                  'facilityID',
                  ParamType.String,
                ),
              ),
            )
          ].map((r) => r.toRoute(appStateNotifier)).toList(),
        ),
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
            return '/homePage';
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
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  child: Center(
                    child: Image.asset(
                      'assets/images/medzen.logo.png',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
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
