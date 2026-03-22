# TOTV+ v12.0

## ملفان مطلوبان قبل البناء
1. `lib/firebase_options.dart` ← من Firebase Console
2. ضع `assets/videos/0320.mp4` (فيديو السبلاش)

## أصول مضمنة ✅
- `assets/images/logo.png` ← أيقونة التطبيق
- `assets/videos/intro.mp4` ← مقدمة الأفلام (6 ثوانٍ)
- جميع أيقونات Android (5 أحجام)
- جميع أيقونات Web PWA
- Windows app_icon.ico

## Build Commands
```bash
flutter build appbundle --release --no-tree-shake-icons
flutter build apk --release --split-per-abi --no-tree-shake-icons
flutter build web --release --base-href / --no-tree-shake-icons
flutter build windows --release --no-tree-shake-icons
```
