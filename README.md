# السيارات المشتركة بالمشروع

تطبيق Flutter عربي للبحث في سجل السيارات، مع بيانات محلية جاهزة ودعم Firebase عند ربط المشروع.

## تقسيمة المشروع

```text
lib/
  app/                         إعداد التطبيق والثيم
  core/                        الثوابت وأدوات البحث
  data/
    models/                    نماذج السيارة والشركة
    local/                     نسخة البيانات المحفوظة على الجهاز
    remote/                    بدء اتصال Firebase
    repositories/              مصدر موحد للبيانات وعمليات الكتابة
  features/
    home/                      تبويب البحث وبطاقات النتائج، وتبويب كل السيارات بجدول أعمدة
    authentication/             دخول الأدمن
    admin/                     إدارة السيارات والنماذج
    companies/                 عرض الشركات وأعداد سياراتها
  shared/                      عناصر واجهة مشتركة
assets/
  image/car.jpeg               الصورة الأصلية التي زودتني بها، مستخدمة في التطبيق والأيقونة
  data/                         سجل الشركات والسيارات وملخص فحص المصدر
firestore.rules                قواعد القراءة العامة والكتابة للأدمن فقط
tools/import_firestore.py      استيراد دفعات Firebase Admin من الملفات المحلية
```

## البيانات الحالية

يحتوي السجل المحلي على 26 شركة و2,459 سيارة فريدة. ملف أغسطس 2026 قدّم 1,909 سيارة؛ قارنت معه ملف مايو 2026 الأقدم وأضفت 550 لوحة كانت ناقصة، مع الإبقاء على السجلات الموجودة دون تعديل. من بيانات مايو، كانت 1,304 لوحة موجودة بالفعل، ولم يظهر تعارض في اسم الشركة للوحات المضافة.

استبعدت من ملف أغسطس 102 صفًا مكررًا بالكامل وصفًا واحدًا ناقصًا من نسخة التطبيق. توجد أربع لوحات مسجلة لأكثر من شركة في المصدر الأساسي، وأبقيتها كما وردت. تفاصيل المصدرين والإضافات وأعداد الشركات في `assets/data/source_import_report.json`.

ملفات JSON هي بيانات البداية المحلية، والبحث يعمل منها دون Firestore. عند تفعيل Firebase، يظل التطبيق عارضًا لهذه البيانات إذا كانت مجموعة `cars` في Firestore فارغة. عند وصول لقطة Firestore غير فارغة من الخادم، يستخدم التطبيق بيانات Firestore باعتبارها النسخة المشتركة بين المستخدمين.

لذلك Firestore اختياري للبحث المحلي فقط، لكنه مطلوب لتسجيل دخول الأدمن وإضافة أو تعديل السيارات ومشاركة التغييرات بين الأجهزة. بعد إنشاء قاعدة Firestore وإعداد Android، استورد ملفات JSON الحالية بالأداة أدناه.

## الربط مع Firebase

لم أضع Project ID أو مفاتيح وهمية. لإكمال الربط:

1. أنشئ Firebase Project، وسجل تطبيق Android بمعرّف الحزمة الظاهر في `android/app/build.gradle.kts`.
2. من Firebase Console افتح Build > Firestore Database واضغط Create database، اختر الموقع، وابدأ بوضع Production. فعّل Email/Password من Authentication > Sign-in method.
3. ثبّت FlutterFire CLI عند الحاجة: `dart pub global activate flutterfire_cli`.
4. في PowerShell ثبّت Firebase CLI عند الحاجة بـ `npm.cmd install -g firebase-tools`، وسجّل الدخول بـ `firebase.cmd login`. بعد ذلك نفّذ: `dart pub global run flutterfire_cli:flutterfire configure --project=cars-19486 --platforms=android,ios,web,windows,macos`. تأكد أن تطبيق Android مسجل بمعرّف الحزمة `com.example.newapp`، وأن تطبيق iOS مسجل بمعرّف الحزمة `com.example.newapp` (حدّثهما إلى معرّفات فريدة قبل النشر العام).
5. تحقق أن `lib/firebase_options.dart` يحتوي إعدادات كل منصة ستبنيها، ثم نفّذ `flutter clean` و`flutter pub get`. إعداد iOS غير موجود حاليًا في الملف حتى تُعاد تهيئته باستخدام FlutterFire CLI.
6. أضيفي كل بريد أدمن في `adminEmails` داخل `lib/core/constants/app_constants.dart`، وأضيفي شرط البريد نفسه داخل `isAdmin()` في `firestore.rules`.
7. أنشئي لكل أدمن حسابًا مستقلًا من Firebase Authentication > Users > Add user، ثم انشري القواعد وأعيدي بناء التطبيق كي تُطبق القائمة الجديدة.
8. انشر القواعد من مجلد المشروع: `firebase.cmd deploy --only firestore:rules --project cars-19486`.
9. بعد تسجيل الدخول للأدمن، استخدم زر السحابة أعلى شاشة إدارة السيارات لرفع بيانات البداية الناقصة. الأداة تضيف السجلات غير الموجودة فقط، ولا تحتاج إلى Python أو مفتاح Service Account.

لإضافة أدمن آخر: أنشئي له مستخدمًا مستقلًا ببريد وكلمة مرور في Authentication، ثم أضيفي البريد نفسه إلى `adminEmails` وإلى شرط `isAdmin()` في القواعد. انشري القواعد، وابني نسخة جديدة من التطبيق. لا تشاركي كلمة مرور الأدمن الحالي.

### تحديث بيانات Excel مستقبلًا

احفظ المصنف بصيغة `.xlsx`، ثم نفذ `python tools/prepare_excel.py --input "C:\\مسار\\ملف.xlsx" --first-data-row 5`. الأداة تقرأ الأعمدة A:C (رقم السيارة، الحروف، الشركة)، وتحدّث ملفات JSON ومعها تقرير بالتكرارات والصفوف الناقصة وتعارض اللوحات. افحص `assets/data/source_import_report.json` قبل استخدام أداة Firebase. ملف `.xls` الأقدم يحتاج حفظ نسخة `.xlsx` أولًا.

Firestore يتيح القراءة دون تسجيل دخول، بينما قواعد الأمان تسمح بالكتابة للبريد المحدد فقط. واجهة Flutter وحدها لا تمنح صلاحية الكتابة. يعمل البحث على السجل الموجود بالجهاز، ويستخدم Firestore Snapshot Listener للتحديث عند الاتصال. يحتفظ التطبيق بنسخة JSON محلية، وتبقى تعديلات Firestore دون اتصال في قائمة انتظار SDK حتى تتوفر الشبكة؛ نجاح الكتابة النهائي يخضع لقواعد Firestore.

## توزيع التطبيق

- لمشاركة نسخة تجريبية مباشرة مع أجهزة Android: نفّذ `flutter build apk --release` وأرسل `build/app/outputs/flutter-apk/app-release.apk`. إعداد Gradle الحالي يوقّع نسخة release بمفتاح debug، لذلك غيّره إلى مفتاح release محفوظ وآمن قبل النشر الرسمي. للنشر في Google Play استخدم `flutter build appbundle --release` بعد إعداد توقيع release؛ ملف AAB في `build/app/outputs/bundle/release/app.aab`.
- بناء iPhone يحتاج macOS وXcode، كما أن إعداد Firebase لـiOS غير مكتمل حاليًا. أضف منصة iOS باستخدام FlutterFire CLI على مشروع بمُعرّف Bundle ID الصحيح، ثم من Mac شغّل `flutter build ipa --release` وارفع ملف IPA إلى App Store Connect لتوزيعه عبر TestFlight أو App Store.
- عند إصدار تحديث، زد رقم البناء بعد علامة `+` في `pubspec.yaml`.

## التشغيل

```bash
flutter pub get
dart run flutter_launcher_icons
flutter run
```

فحص الكود والاختبارات:

```bash
flutter analyze
flutter test
```

لتحديث صور أيقونة المنصات لاحقًا شغّل `dart run flutter_launcher_icons`؛ المصدر دائمًا `assets/image/car.jpeg` ولا يتغير.
