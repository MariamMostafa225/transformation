import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/plate_search.dart';
import '../../../data/models/car.dart';
import '../../../data/models/company.dart';
import '../controllers/car_catalog_controller.dart';

class AllCarsTab extends StatefulWidget {
  const AllCarsTab({super.key});

  @override
  State<AllCarsTab> createState() => _AllCarsTabState();
}

class _AllCarsTabState extends State<AllCarsTab> {
  final _search = TextEditingController();
  String? _companyId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarCatalogController>(
      builder: (context, catalog, _) {
        final companies = {
          for (final company in catalog.companies) company.id: company,
        };
        final cars = catalog.cars
            .where((car) {
              final matchesCompany =
                  _companyId == null || car.companyId == _companyId;
              return matchesCompany &&
                  containsPlateQuery(
                    query: _search.text,
                    carNumber: car.carNumber,
                    letters: car.letters,
                    companyName: car.companyName,
                  );
            })
            .toList(growable: false);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'كل السيارات',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${cars.length} سيارة',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث بالرقم أو الحروف أو الشركة',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String?>(
                    initialValue: _companyId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'تصفية حسب الشركة',
                      prefixIcon: Icon(Icons.filter_alt_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('كل الشركات'),
                      ),
                      ...catalog.companies.map(
                        (company) => DropdownMenuItem<String?>(
                          value: company.id,
                          child: Text(
                            company.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _companyId = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TableHeader(),
            ),
            Expanded(
              child: cars.isEmpty
                  ? const _NoCars()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: cars.length,
                      itemBuilder: (context, index) => _CarTableRow(
                        car: cars[index],
                        company: companies[cars[index].companyId],
                      ),
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 8, endIndent: 8),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFE5EEEB),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
    ),
    child: const Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'رقم السيارة',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text('الحروف', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        Expanded(
          flex: 3,
          child: Text('الشركة', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}

class _CarTableRow extends StatelessWidget {
  const _CarTableRow({required this.car, required this.company});

  final Car car;
  final Company? company;

  @override
  Widget build(BuildContext context) {
    final color = company?.colorValue ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                car.carNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                car.letters,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: color, radius: 4),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      car.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoCars extends StatelessWidget {
  const _NoCars();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.table_rows_outlined, size: 48, color: Colors.blueGrey),
        SizedBox(height: 10),
        Text('لا توجد سيارات مطابقة للفلاتر الحالية.'),
      ],
    ),
  );
}
