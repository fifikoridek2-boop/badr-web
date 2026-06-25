# طلب السحب (Pull Request)

## التفاصيل

**العنوان:** `fix: تحسين جاهزية التطبيق للنشر على Android`

**من الفرع:** `fix/android-release-readiness`
**إلى الفرع:** `main`

## الوصف (للنسخ):

```
## ملخص التغييرات

تم إجراء تحسينات شاملة للتطبيق لتحسين جاهزيته للنشر على Android:

### 🔧 إصلاحات Android

| الملف | التغيير |
|-------|--------|
| AndroidManifest.xml | تغيير الاسم إلى 'بدر' + إضافة صلاحيات الإشعارات والتشغيل في الخلفية |
| build.gradle.kts | تحديد SDK صراحة + تفعيل Release signing + ProGuard |
| proguard-rules.pro | قواعد إخفاء الكود |

### 📱 الميزات الجديدة

- NotificationService: خدمة الإشعارات المحلية للصلاة
- flutter_local_notifications: جدولة إشعارات الصلاة
- بيانات offline: أذكار محلية تعمل بدون إنترنت
- Cache: حفظ بيانات الأذكار محلياً

### 🐛 إصلاحات الأخطاء

- معالجة أفضل للأخطاء في HomeProvider و AzkarProvider
- Fallback للأذكار عند فشل الاتصال
- حفظ تقدم الأذكار في Cache

---
*تم إنشاء هذا الـ PR بواسطة AI agent (OpenHands)*
```

## الملفات المعدلة:

1. `android/app/build.gradle.kts`
2. `android/app/src/main/AndroidManifest.xml`
3. `android/app/proguard-rules.pro` (جديد)
4. `lib/core/services/notification_service.dart` (جديد)
5. `lib/features/azkar/azkar_provider.dart`
6. `lib/features/home/home_provider.dart`
7. `pubspec.yaml`

## لإنشاء الـ PR يدوياً:

1. اذهب إلى: https://github.com/fifikoridek2-boop/badr-web
2. ستجد رسالة "Compare & pull request" للفرع الجديد
3. اضغط عليها
4. الصق الوصف أعلاه
5. اضغط "Create pull request"