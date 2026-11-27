import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plasvora/core/theme/app_colors.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/core/widgets/app_bottom_nav.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/repositories/gallery_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/viewmodels/analysis_viewmodel.dart';
import 'package:plasvora/viewmodels/gallery_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/viewmodels/navigation_viewmodel.dart';
import 'package:plasvora/views/analysis/analysis_screen.dart';
import 'package:plasvora/views/gallery/gallery_screen.dart';
import 'package:plasvora/views/home/home_screen.dart';
import 'package:plasvora/views/main_navigation_screen.dart';
import 'package:plasvora/views/marketplace/marketplace_screen.dart';
import 'package:plasvora/views/profile/profile_screen.dart';

void main() {
  late bool previousAllowRuntimeFetching;

  setUpAll(() {
    previousAllowRuntimeFetching = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() {
    GoogleFonts.config.allowRuntimeFetching = previousAllowRuntimeFetching;
  });

  Widget buildMainNavApp(
    NavigationViewModel navVm, {
    double textScale = 1.0,
    double bottomSafeArea = 0.0,
    bool disableAnimations = false,
  }) {
    final materialRepo = MockMaterialRepository(simulateDelay: false);
    final galleryVm = GalleryViewModel(
      galleryRepository: MockGalleryRepository(),
    );

    return MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: mq.padding.copyWith(bottom: bottomSafeArea),
            viewPadding: mq.viewPadding.copyWith(bottom: bottomSafeArea),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        );
      },
      home: MainNavigationScreen(
        navigationViewModel: navVm,
        homeViewModel: HomeViewModel(materialRepository: materialRepo),
        analysisViewModel: AnalysisViewModel(
          analysisRepository: MockAnalysisRepository(),
        ),
        marketplaceViewModel: MarketplaceViewModel(
          materialRepository: materialRepo,
        ),
        galleryViewModel: galleryVm,
      ),
    );
  }

  group('NavigationViewModel Index Mapping', () {
    test('uses Beranda -> Galeri -> Analisis -> Marketplace -> Profil order', () {
      expect(NavigationViewModel.homeIndex, 0);
      expect(NavigationViewModel.galleryIndex, 1);
      expect(NavigationViewModel.analysisIndex, 2);
      expect(NavigationViewModel.marketplaceIndex, 3);
      expect(NavigationViewModel.profileIndex, 4);

      final vm = NavigationViewModel();
      expect(vm.currentIndex, 0);

      vm.goToGallery();
      expect(vm.currentIndex, 1);

      vm.goToAnalysis();
      expect(vm.currentIndex, 2);

      vm.goToMarketplace();
      expect(vm.currentIndex, 3);

      vm.goToProfile();
      expect(vm.currentIndex, 4);

      vm.goToActivity();
      expect(vm.currentIndex, 4);

      vm.goToHome();
      expect(vm.currentIndex, 0);
    });
  });

  group('AppBottomNav Order, Equal Slots, Alignment & Mapping', () {
    testWidgets(
      'renders 5 equal 20% slots, W*(0.1..0.9) icon centers, shared 5-label baseline, and maps each destination',
      (tester) async {
        final navVm = NavigationViewModel();
        await tester.pumpWidget(buildMainNavApp(navVm));
        await tester.pumpAndSettle();

        final bottomNav = find.byType(AppBottomNav);
        expect(bottomNav, findsOneWidget);
        final navRect = tester.getRect(bottomNav);
        final expectedSlotWidth = navRect.width / 5;

        const labels = ['Beranda', 'Galeri', 'Analisis', 'Marketplace', 'Profil'];
        const centerRatios = [0.1, 0.3, 0.5, 0.7, 0.9];

        final slotRects = <Rect>[];
        final iconCenters = <Offset>[];
        final labelRects = <Rect>[];

        for (var i = 0; i < 5; i++) {
          final slotFinder = find.byKey(AppBottomNav.slotKey(i));
          final iconFinder = find.byKey(AppBottomNav.iconKey(i));
          final labelFinder = find.descendant(
            of: bottomNav,
            matching: find.text(labels[i]),
          );

          expect(slotFinder, findsOneWidget);
          expect(iconFinder, findsOneWidget);
          expect(labelFinder, findsOneWidget);

          final slotRect = tester.getRect(slotFinder);
          final iconCenter = tester.getCenter(iconFinder);
          final labelRect = tester.getRect(labelFinder);

          // Each item occupies exactly 20% of the navbar width and >= 48x48 touch target
          expect(slotRect.width, closeTo(expectedSlotWidth, 0.5));
          expect(slotRect.width, greaterThanOrEqualTo(48.0));
          expect(slotRect.height, greaterThanOrEqualTo(48.0));

          // Each icon center aligns with W * (0.1, 0.3, 0.5, 0.7, 0.9) and its own slot center
          final expectedCenterX = navRect.left + (navRect.width * centerRatios[i]);
          expect(iconCenter.dx, closeTo(expectedCenterX, 1.0));
          expect(iconCenter.dx, closeTo(slotRect.center.dx, 1.0));

          // Label stays strictly inside its own slot (Marketplace never overflows)
          expect(labelRect.left, greaterThanOrEqualTo(slotRect.left));
          expect(labelRect.right, lessThanOrEqualTo(slotRect.right));

          slotRects.add(slotRect);
          iconCenters.add(iconCenter);
          labelRects.add(labelRect);
        }

        // Uniform horizontal deltas between adjacent icon centers
        for (var i = 0; i < 4; i++) {
          final delta = iconCenters[i + 1].dx - iconCenters[i].dx;
          expect(delta, closeTo(expectedSlotWidth, 1.0));
        }

        // Analisis is centered at exactly W / 2
        expect(iconCenters[2].dx, closeTo(navRect.center.dx, 0.5));
        expect(slotRects[2].center.dx, closeTo(navRect.center.dx, 0.5));

        // All 5 labels (including Analisis) share the same vertical center & bottom baseline
        final baselineCenterY = labelRects.first.center.dy;
        final baselineBottom = labelRects.first.bottom;
        for (var i = 1; i < 5; i++) {
          expect(
            (labelRects[i].center.dy - baselineCenterY).abs(),
            lessThanOrEqualTo(1.0),
            reason: '${labels[i]} label center Y drifted',
          );
          expect(
            (labelRects[i].bottom - baselineBottom).abs(),
            lessThanOrEqualTo(1.0),
            reason: '${labels[i]} label bottom drifted',
          );
        }

        // Four normal icons share the same vertical center; Analisis icon sits subtly elevated
        final normalIconY = iconCenters[0].dy;
        for (final idx in const [1, 3, 4]) {
          expect((iconCenters[idx].dy - normalIconY).abs(), lessThanOrEqualTo(1.0));
        }
        expect(iconCenters[2].dy, lessThan(normalIconY));

        IndexedStack rootIndexedStack() {
          final scaffold = tester.widget<Scaffold>(
            find
                .descendant(
                  of: find.byType(MainNavigationScreen),
                  matching: find.byType(Scaffold),
                )
                .first,
          );
          return scaffold.body! as IndexedStack;
        }

        // Verify IndexedStack maps each index to its exact screen type
        final stack = rootIndexedStack();
        expect(stack.children, hasLength(5));
        expect(stack.children[0], isA<HomeScreen>());
        expect(stack.children[1], isA<GalleryScreen>());
        expect(stack.children[2], isA<AnalysisScreen>());
        expect(stack.children[3], isA<MarketplaceScreen>());
        expect(stack.children[4], isA<ProfileScreen>());

        // Tap every destination and confirm correct active index
        final expectedIndices = {
          'Galeri': NavigationViewModel.galleryIndex,
          'Analisis': NavigationViewModel.analysisIndex,
          'Marketplace': NavigationViewModel.marketplaceIndex,
          'Profil': NavigationViewModel.profileIndex,
          'Beranda': NavigationViewModel.homeIndex,
        };
        for (final entry in expectedIndices.entries) {
          await tester.tap(
            find.descendant(of: bottomNav, matching: find.text(entry.key)),
          );
          await tester.pumpAndSettle();
          expect(navVm.currentIndex, entry.value);
          expect(rootIndexedStack().index, entry.value);
        }
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('AppBottomNav Visual Hierarchy, Micro-Interactions, Haptics & Accessibility', () {
    testWidgets(
      'keeps Analisis 56px circle + visible label in unselected & selected states with restrained shadow and haptic',
      (tester) async {
        final hapticCalls = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add('${call.arguments}');
          }
          return null;
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        int activeIndex = NavigationViewModel.homeIndex;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: const SizedBox.expand(),
                  bottomNavigationBar: AppBottomNav(
                    currentIndex: activeIndex,
                    onTabSelected: (idx) => setState(() => activeIndex = idx),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Unselected Analisis: 56x56 circle, 26px white icon, subtle shadow (no outer spread glow), visible semibold label
        final badgeFinder = find.byKey(AppBottomNav.analysisBadgeKey);
        expect(badgeFinder, findsOneWidget);

        final unselectedSize = tester.getSize(badgeFinder);
        expect(unselectedSize.width, inInclusiveRange(56.0, 60.0));
        expect(unselectedSize.height, inInclusiveRange(56.0, 60.0));

        final unselectedBadge = tester.widget<AnimatedContainer>(badgeFinder);
        final unselectedDecoration = unselectedBadge.decoration! as BoxDecoration;
        expect(unselectedDecoration.color, const Color(0xFF0D3B2E));
        expect(unselectedDecoration.shape, BoxShape.circle);
        expect(unselectedDecoration.boxShadow, hasLength(1));
        expect(unselectedDecoration.boxShadow!.single.spreadRadius, 0.0);

        final analysisScaleFinder = find
            .ancestor(of: badgeFinder, matching: find.byType(AnimatedScale))
            .first;
        expect(tester.widget<AnimatedScale>(analysisScaleFinder).scale, 1.0);

        final unselectedIcon = tester.widget<Icon>(
          find.descendant(of: badgeFinder, matching: find.byType(Icon)),
        );
        expect(unselectedIcon.color, AppColors.onPrimary);
        expect(unselectedIcon.size, inInclusiveRange(25.0, 28.0));
        expect(unselectedIcon.icon, Icons.document_scanner_outlined);

        expect(find.text('Analisis'), findsOneWidget);
        final unselectedLabelStyle = tester
            .widget<AnimatedDefaultTextStyle>(
              find
                  .ancestor(
                    of: find.text('Analisis'),
                    matching: find.byType(AnimatedDefaultTextStyle),
                  )
                  .first,
            )
            .style;
        expect(unselectedLabelStyle.fontWeight, FontWeight.w600);

        // Ordinary selected item (Beranda) preserves existing mint pill indicator
        final berandaPill = tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.byIcon(Icons.home),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        expect(
          (berandaPill.decoration! as BoxDecoration).color,
          AppColors.secondaryContainer,
        );

        // Tapping already-selected Beranda does NOT fire extra haptic
        await tester.tap(find.byKey(AppBottomNav.slotKey(0)));
        await tester.pumpAndSettle();
        expect(hapticCalls, isEmpty);

        // Press down on Analisis -> subtle press scale-down (0.97), release -> selected (1.04) + haptic
        final gesture = await tester.startGesture(tester.getCenter(badgeFinder));
        await tester.pump(const Duration(milliseconds: 60));
        expect(
          tester.widget<AnimatedScale>(analysisScaleFinder).scale,
          inInclusiveRange(0.96, 0.98),
        );
        await gesture.up();
        await tester.pumpAndSettle();

        expect(activeIndex, NavigationViewModel.analysisIndex);
        expect(hapticCalls, contains('HapticFeedbackType.selectionClick'));
        expect(
          tester.widget<AnimatedScale>(analysisScaleFinder).scale,
          inInclusiveRange(1.03, 1.05),
        );

        final selectedBadge = tester.widget<AnimatedContainer>(badgeFinder);
        final selectedDecoration = selectedBadge.decoration! as BoxDecoration;
        expect(selectedDecoration.color, const Color(0xFF0D3B2E));
        expect(
          (selectedDecoration.border! as Border).top.color,
          AppColors.primaryFixed,
        );
        expect(selectedDecoration.boxShadow, hasLength(1));
        expect(selectedDecoration.boxShadow!.single.spreadRadius, 0.0);

        final selectedIcon = tester.widget<Icon>(
          find.descendant(of: badgeFinder, matching: find.byType(Icon)),
        );
        expect(selectedIcon.color, AppColors.onPrimary);
        expect(selectedIcon.icon, Icons.document_scanner);

        expect(find.text('Analisis'), findsOneWidget);
        final selectedLabelStyle = tester
            .widget<AnimatedDefaultTextStyle>(
              find
                  .ancestor(
                    of: find.text('Analisis'),
                    matching: find.byType(AnimatedDefaultTextStyle),
                  )
                  .first,
            )
            .style;
        expect(selectedLabelStyle.fontWeight, FontWeight.w700);

        // Beranda pill returns to transparent
        final inactiveBerandaPill = tester.widget<AnimatedContainer>(
          find
              .ancestor(
                of: find.byIcon(Icons.home_outlined),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        expect(
          (inactiveBerandaPill.decoration! as BoxDecoration).color,
          Colors.transparent,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'respects reduced motion (disableAnimations) and exposes clean Semantics without duplicate labels',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: Scaffold(
                body: const SizedBox.expand(),
                bottomNavigationBar: AppBottomNav(
                  currentIndex: NavigationViewModel.analysisIndex,
                  onTabSelected: (_) {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final badgeFinder = find.byKey(AppBottomNav.analysisBadgeKey);
          final badge = tester.widget<AnimatedContainer>(badgeFinder);
          expect(badge.duration, Duration.zero);

          final scaleWidget = tester.widget<AnimatedScale>(
            find
                .ancestor(of: badgeFinder, matching: find.byType(AnimatedScale))
                .first,
          );
          expect(scaleWidget.scale, 1.0);
          expect(scaleWidget.duration, Duration.zero);

          final analysisNode = tester.getSemantics(
            find.byKey(AppBottomNav.slotKey(NavigationViewModel.analysisIndex)),
          );
          expect(
            analysisNode,
            matchesSemantics(
              label: 'Analisis',
              isButton: true,
              isFocusable: true,
              hasSelectedState: true,
              isSelected: true,
              hasTapAction: true,
              hasFocusAction: true,
            ),
          );

          final homeNode = tester.getSemantics(
            find.byKey(AppBottomNav.slotKey(NavigationViewModel.homeIndex)),
          );
          expect(
            homeNode,
            matchesSemantics(
              label: 'Beranda',
              isButton: true,
              isFocusable: true,
              hasSelectedState: true,
              isSelected: false,
              hasTapAction: true,
              hasFocusAction: true,
            ),
          );
        } finally {
          semanticsHandle.dispose();
        }
      },
    );
  });

  group('AppBottomNav Responsive Geometry Across Exact Android Viewports', () {
    const viewports = <Size>[
      Size(360, 800),
      Size(375, 812),
      Size(393, 873),
      Size(412, 915),
    ];

    for (final viewport in viewports) {
      testWidgets(
        'measures balanced 20% slots, W*(0.1..0.9) icon centers, and 5-label baseline at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final navVm = NavigationViewModel();
          await tester.pumpWidget(
            buildMainNavApp(navVm, bottomSafeArea: 24.0),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          final bottomNav = find.byType(AppBottomNav);
          final navRect = tester.getRect(bottomNav);
          final expectedSlotWidth = viewport.width / 5;

          // Analysis circle stays completely inside navbar bounds (unclipped)
          final badgeRect = tester.getRect(
            find.byKey(AppBottomNav.analysisBadgeKey),
          );
          expect(badgeRect.top, greaterThanOrEqualTo(navRect.top));
          expect(badgeRect.bottom, lessThanOrEqualTo(navRect.bottom));
          expect(badgeRect.left, greaterThanOrEqualTo(navRect.left));
          expect(badgeRect.right, lessThanOrEqualTo(navRect.right));
          expect(badgeRect.center.dx, closeTo(viewport.width / 2, 0.5));

          const labels = ['Beranda', 'Galeri', 'Analisis', 'Marketplace', 'Profil'];
          const centerRatios = [0.1, 0.3, 0.5, 0.7, 0.9];

          final measuredIconCenters = <Offset>[];
          final measuredLabelCentersY = <double>[];
          final measuredLabelBottoms = <double>[];
          Rect? previousLabelRect;

          for (var i = 0; i < 5; i++) {
            final slotRect = tester.getRect(find.byKey(AppBottomNav.slotKey(i)));
            final iconCenter = tester.getCenter(
              find.byKey(AppBottomNav.iconKey(i)),
            );
            final labelRect = tester.getRect(
              find.descendant(of: bottomNav, matching: find.text(labels[i])),
            );

            expect(slotRect.width, closeTo(expectedSlotWidth, 0.5));
            expect(
              iconCenter.dx,
              closeTo(viewport.width * centerRatios[i], 1.0),
            );
            expect(iconCenter.dx, closeTo(slotRect.center.dx, 1.0));
            expect(labelRect.left, greaterThanOrEqualTo(slotRect.left));
            expect(labelRect.right, lessThanOrEqualTo(slotRect.right));

            if (previousLabelRect != null) {
              expect(
                previousLabelRect.right,
                lessThan(labelRect.left),
                reason:
                    'Label ${labels[i]} overlaps previous label at ${viewport.width.toInt()}px',
              );
            }
            previousLabelRect = labelRect;
            measuredIconCenters.add(iconCenter);
            measuredLabelCentersY.add(labelRect.center.dy);
            measuredLabelBottoms.add(labelRect.bottom);
          }

          // Adjacent icon center gaps are equal
          for (var i = 0; i < 4; i++) {
            final gap = measuredIconCenters[i + 1].dx - measuredIconCenters[i].dx;
            expect(gap, closeTo(expectedSlotWidth, 1.0));
          }

          // All 5 labels share the same vertical center & bottom baseline
          for (var i = 1; i < 5; i++) {
            expect(
              (measuredLabelCentersY[i] - measuredLabelCentersY.first).abs(),
              lessThanOrEqualTo(1.0),
            );
            expect(
              (measuredLabelBottoms[i] - measuredLabelBottoms.first).abs(),
              lessThanOrEqualTo(1.0),
            );
          }

          // Navbar respects safe area without covering body content
          final rootStackFinder = find
              .descendant(
                of: find.byType(MainNavigationScreen),
                matching: find.byType(IndexedStack),
              )
              .first;
          final scaffoldBodyRect = tester.getRect(rootStackFinder);
          expect(scaffoldBodyRect.bottom, lessThanOrEqualTo(navRect.top + 0.5));
        },
      );
    }

    testWidgets(
      'AppBottomNav renders without overflow or badge clipping at 360x800 with 1.3x text scaling and Analisis selected',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: const TextScaler.linear(1.3),
                  padding: mq.padding.copyWith(bottom: 24.0),
                  viewPadding: mq.viewPadding.copyWith(bottom: 24.0),
                ),
                child: child!,
              );
            },
            home: Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: AppBottomNav(
                currentIndex: NavigationViewModel.analysisIndex,
                onTabSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final bottomNav = find.byType(AppBottomNav);
        final navRect = tester.getRect(bottomNav);
        final badgeRect = tester.getRect(
          find.byKey(AppBottomNav.analysisBadgeKey),
        );
        expect(find.text('Analisis'), findsOneWidget);
        expect(badgeRect.top, greaterThanOrEqualTo(navRect.top));
        expect(badgeRect.bottom, lessThanOrEqualTo(navRect.bottom));
      },
    );
  });
}
