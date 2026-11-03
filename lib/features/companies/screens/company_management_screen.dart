import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/home/controllers/car_catalog_controller.dart';

class CompanyManagementScreen extends StatelessWidget {
  const CompanyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarCatalogController>(
      builder: (context, catalog, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('الشركات المسجلة')),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: catalog.companies.length,
            itemBuilder: (context, index) {
              final company = catalog.companies[index];
              final count = catalog.countForCompany(company.id);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: company.colorValue,
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  title: Text(
                    company.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('$count سيارة'),
                  trailing: Text(
                    '$count',
                    style: TextStyle(
                      color: company.colorValue,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 9),
          ),
        );
      },
    );
  }
}
