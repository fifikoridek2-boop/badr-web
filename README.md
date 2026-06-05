# بدر (Flutter)

تطبيق Flutter للقرآن والأذكار.

## تشغيل محلي
```bash
flutter pub get
flutter run
```

## بناء نسخة ويب
```bash
flutter pub get
flutter build web --release
```

## نشر على Vercel (بدون التأثير على APK)
تمت إضافة إعدادات مخصصة ليتولى Vercel تثبيت Flutter ثم بناء نسخة الويب:
- `vercel.json`
- `vercel-build.sh`

### إعدادات مشروع Vercel
1. ادخل مشروعك في Vercel.
2. **Framework Preset** = `Other`.
3. اترك Build Command من `vercel.json` (أو اجعله: `bash ./vercel-build.sh`).
4. Output Directory = `build/web`.
5. أعد النشر Redeploy.

### متغيرات اختيارية
يمكنك تحديد نسخة Flutter عبر متغير بيئة في Vercel:
- `FLUTTER_VERSION` (افتراضي: `3.41.3`)
- `FLUTTER_CHANNEL` (افتراضي: `stable`)

> ملاحظة: هذه الإعدادات تخص الويب فقط ولا تعدّل ملفات `android/` أو توقيع APK.
