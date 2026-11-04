import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../controllers/car_catalog_controller.dart';
import '../widgets/car_card.dart';
import '../../authentication/screens/admin_login_screen.dart';
import '../../companies/screens/company_management_screen.dart';
import '../../admin/screens/admin_cars_screen.dart';
import 'all_cars_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdmin() async {
    final signedIn = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
    if (!mounted || signedIn != true) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AdminCarsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarCatalogController>(
      builder: (context, catalog, _) {
        final visible = catalog.visibleCars;
        final companies = {for (final c in catalog.companies) c.id: c};
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            actions: [
              IconButton(
                tooltip: 'دخول الأدمن',
                onPressed: _openAdmin,
                icon: const Icon(Icons.admin_panel_settings_outlined),
              ),
              IconButton(
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'تفعيل الوضع الفاتح'
                    : 'تفعيل الوضع الداكن',
                onPressed: widget.onToggleTheme,
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _selectedTab == 0
              ? CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                      sliver: SliverList.list(
                        children: [
                          _WelcomePanel(totalCars: catalog.cars.length),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _searchController,
                            onChanged: catalog.setQuery,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'ابحث برقم السيارة أو الحروف أو الشركة',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon:
                                  catalog.query.isNotEmpty ||
                                      _searchController.text.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'مسح البحث',
                                      onPressed: () {
                                        _searchController.clear();
                                        catalog.clearQuery();
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SyncStatus(catalog: catalog),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Text(
                                'الشركات',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CompanyManagementScreen(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.business_outlined,
                                  size: 18,
                                ),
                                label: const Text('عرض الشركات'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 43,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 8,
                                  ),
                                  child: FilterChip(
                                    label: Text('الكل  ${catalog.cars.length}'),
                                    selected: catalog.selectedCompanyId == null,
                                    onSelected: (_) =>
                                        catalog.selectCompany(null),
                                  ),
                                ),
                                ...catalog.companies.map(
                                  (company) => Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 8,
                                    ),
                                    child: FilterChip(
                                      avatar: CircleAvatar(
                                        backgroundColor: company.colorValue,
                                        radius: 7,
                                      ),
                                      label: Text(
                                        '${company.name}  ${catalog.countForCompany(company.id)}',
                                      ),
                                      selected:
                                          catalog.selectedCompanyId ==
                                          company.id,
                                      onSelected: (_) =>
                                          catalog.selectCompany(company.id),
                                      selectedColor: company.colorValue
                                          .withValues(alpha: 0.16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 21),
                          Text(
                            'النتائج  ${visible.length}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    if (visible.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyResults(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                        sliver: SliverList.separated(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final car = visible[index];
                            return CarCard(
                              car: car,
                              company: companies[car.companyId],
                            );
                          },
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                        ),
                      ),
                  ],
                )
              : const AllCarsTab(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) =>
                setState(() => _selectedTab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: 'البحث',
              ),
              NavigationDestination(
                icon: Icon(Icons.table_rows_rounded),
                label: 'كل السيارات',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.totalCars});

  final int totalCars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF203B3A), Color(0xFF263231)]
              : const [Color(0xFFE4F0ED), Color(0xFFF4F7F3)],
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.asset(
              'assets/image/car.jpeg',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دليل السيارات',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCars سيارة مسجلة لدى الشركات',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.directions_car_filled_outlined,
            color: AppConstants.primary,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.catalog});

  final CarCatalogController catalog;

  @override
  Widget build(BuildContext context) {
    final online = catalog.isSynced;
    final color = catalog.remoteCatalogEmpty
        ? const Color(0xFF98713D)
        : online
        ? const Color(0xFF2F8060)
        : const Color(0xFF98713D);
    final status = catalog.hasRemoteError
        ? 'تعذر الاتصال؛ يتم عرض البيانات المحفوظة'
        : catalog.hasPendingWrites
        ? 'تغييرات محفوظة محليًا وتنتظر المزامنة'
        : catalog.remoteCatalogEmpty
        ? 'Firestore فارغ — تُعرض السيارات المحلية'
        : online
        ? 'متصل — تمت المزامنة'
        : 'وضع محلي — ستظهر البيانات المحفوظة';
    return Row(
      children: [
        Icon(
          online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          size: 17,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(status, style: TextStyle(fontSize: 12, color: color)),
        ),
        if (catalog.lastSyncAt != null)
          Text(
            'آخر مزامنة ${TimeOfDay.fromDateTime(catalog.lastSyncAt!).format(context)}',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: Colors.blueGrey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'لا توجد سيارات مطابقة',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 5),
          Text(
            'جرّب رقمًا أو حروفًا أو اسم شركة مختلفًا',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
