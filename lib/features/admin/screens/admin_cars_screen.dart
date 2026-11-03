import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/plate_search.dart';
import '../../../data/models/car.dart';
import '../../../data/remote/firebase_bootstrap.dart';
import '../../../features/home/controllers/car_catalog_controller.dart';
import '../../../features/home/widgets/car_card.dart';
import '../../companies/screens/company_management_screen.dart';
import 'car_form_dialog.dart';

class AdminCarsScreen extends StatefulWidget {
  const AdminCarsScreen({super.key});

  @override
  State<AdminCarsScreen> createState() => _AdminCarsScreenState();
}

class _AdminCarsScreenState extends State<AdminCarsScreen> {
  final _search = TextEditingController();
  CarCatalogController? _observedCatalog;
  int _lastShownErrorSerial = 0;
  bool _uploadingCatalog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final catalog = context.read<CarCatalogController>();
    if (_observedCatalog == catalog) return;
    _observedCatalog?.removeListener(_onCatalogChanged);
    _observedCatalog = catalog..addListener(_onCatalogChanged);
    _onCatalogChanged();
  }

  void _onCatalogChanged() {
    final catalog = _observedCatalog;
    if (!mounted ||
        catalog == null ||
        catalog.writeErrorSerial == _lastShownErrorSerial) {
      return;
    }
    _lastShownErrorSerial = catalog.writeErrorSerial;
    final message = catalog.lastWriteError;
    if (message == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _message(message);
    });
  }

  @override
  void dispose() {
    _observedCatalog?.removeListener(_onCatalogChanged);
    _search.dispose();
    super.dispose();
  }

  bool _isDuplicate(
    CarCatalogController catalog,
    CarFormResult form, {
    Car? editing,
  }) {
    return catalog.cars.any(
      (car) =>
          car.id != editing?.id &&
          car.companyId == form.companyId &&
          normalizeArabic(car.carNumber) == normalizeArabic(form.carNumber) &&
          compactArabic(car.letters) == compactArabic(form.letters),
    );
  }

  Future<void> _edit(CarCatalogController catalog, {Car? car}) async {
    final form = await showCarFormDialog(
      context: context,
      companies: catalog.companies,
      car: car,
    );
    if (!mounted || form == null) return;
    if (_isDuplicate(catalog, form, editing: car)) {
      _message('هذه السيارة مسجلة بالفعل لدى الشركة نفسها.');
      return;
    }
    if (!FirebaseBootstrap.initialized) {
      _message('اربط Firebase أولًا قبل إجراء التعديلات.');
      return;
    }
    if (car == null) {
      catalog.repository.addCar(
        carNumber: form.carNumber,
        letters: form.letters,
        companyId: form.companyId,
      );
    } else {
      catalog.repository.updateCar(
        carId: car.id,
        carNumber: form.carNumber,
        letters: form.letters,
        companyId: form.companyId,
      );
    }
    _message('تم إرسال التغيير إلى Firestore؛ جارٍ انتظار تأكيد الحفظ.');
  }

  Future<void> _delete(CarCatalogController catalog, Car car) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السيارة؟'),
        content: Text(
          'سيتم حذف السيارة ${car.carNumber} ${car.letters} من سجل الشركة ${car.companyName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    catalog.repository.deleteCar(car.id);
    _message('تم إرسال طلب الحذف إلى Firestore؛ جارٍ انتظار تأكيده.');
  }

  Future<void> _uploadLocalCatalog() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استكمال سجل السيارات في Firestore؟'),
        content: const Text(
          'سيضيف التطبيق الشركات والسيارات المحلية غير الموجودة فقط. '
          'لن يحذف أو يستبدل أي سجل موجود، بما فيه السيارة 0000.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('بدء الرفع'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted || _uploadingCatalog) return;

    setState(() => _uploadingCatalog = true);
    _message('جارٍ فحص Firestore ورفع السجلات الناقصة...');
    try {
      final result = await context
          .read<CarCatalogController>()
          .repository
          .uploadMissingCatalog();
      if (!mounted) return;
      _message(
        'اكتمل الرفع: ${result.carsAdded} سيارة و${result.companiesAdded} شركة جديدة. '
        'تم تجاوز ${result.carsAlreadyPresent} سيارة موجودة بالفعل.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _message(
        'فشل رفع السجل (${error.code}): ${error.message ?? 'تحقق من قواعد Firestore والاتصال.'}',
      );
    } catch (error) {
      if (!mounted) return;
      _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingCatalog = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarCatalogController>(
      builder: (context, catalog, _) {
        final cars = catalog.visibleCars;
        return Scaffold(
          appBar: AppBar(
            title: const Text('إدارة السيارات'),
            actions: [
              IconButton(
                tooltip: 'رفع السيارات المحلية إلى Firestore',
                onPressed: _uploadingCatalog ? null : _uploadLocalCatalog,
                icon: _uploadingCatalog
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
              ),
              IconButton(
                tooltip: 'الشركات',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompanyManagementScreen(),
                  ),
                ),
                icon: const Icon(Icons.business_outlined),
              ),
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(catalog),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة سيارة'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: catalog.setQuery,
                      decoration: InputDecoration(
                        hintText: 'بحث داخل السيارات',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _search.clear();
                                  catalog.clearQuery();
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    DropdownButtonFormField<String?>(
                      initialValue: catalog.selectedCompanyId,
                      decoration: const InputDecoration(
                        labelText: 'فلترة حسب الشركة',
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
                            child: Text(company.name),
                          ),
                        ),
                      ],
                      onChanged: catalog.selectCompany,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'عدد النتائج: ${cars.length}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: cars.isEmpty
                    ? const Center(child: Text('لا توجد سيارات مطابقة.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: cars.length,
                        itemBuilder: (context, index) {
                          final car = cars[index];
                          final company = catalog.companies
                              .where((c) => c.id == car.companyId)
                              .firstOrNull;
                          return Row(
                            children: [
                              Expanded(
                                child: CarCard(car: car, company: company),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'إجراءات السيارة',
                                onSelected: (value) => value == 'edit'
                                    ? _edit(catalog, car: car)
                                    : _delete(catalog, car),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('تعديل'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete_outline),
                                      title: Text('حذف'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
