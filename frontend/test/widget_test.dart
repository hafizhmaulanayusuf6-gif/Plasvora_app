import 'package:flutter_test/flutter_test.dart';
import 'package:plasvora/main.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/viewmodels/analysis_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/viewmodels/navigation_viewmodel.dart';

void main() {
  testWidgets('Plasvora smoke test loads app and navigation', (
    WidgetTester tester,
  ) async {
    final materialRepo = MockMaterialRepository(simulateDelay: false);
    final analysisRepo = MockAnalysisRepository();

    final navVM = NavigationViewModel();
    final homeVM = HomeViewModel(materialRepository: materialRepo);
    final analysisVM = AnalysisViewModel(analysisRepository: analysisRepo);
    final marketplaceVM = MarketplaceViewModel(
      materialRepository: materialRepo,
    );

    await tester.pumpWidget(
      PlasvoraApp(
        navigationViewModel: navVM,
        homeViewModel: homeVM,
        analysisViewModel: analysisVM,
        marketplaceViewModel: marketplaceVM,
      ),
    );
    await tester.pumpAndSettle();

    // Verify app brand text is rendered
    expect(find.text('PLASVORA'), findsOneWidget);
    expect(find.text('Beranda'), findsWidgets);
  });
}
