# TOTV+ v12.0 — جاهز للبناء الفوري ✅

## الملف الوحيد المتبقي
```
assets/videos/0320.mp4  ← فيديو السبلاش
```

## Firestore Collections المطلوبة
```
vip_users/           ← مستخدمو VIP (username/password/xtream_*)
activation_codes/    ← كودات الاشتراك العادي
app_config/subscription ← buy_url, support_whatsapp, support_telegram
```

## أوامر البناء
```bash
# Android
flutter build appbundle --release --no-tree-shake-icons

# Web
flutter build web --release --base-href / --no-tree-shake-icons

# Windows
flutter build windows --release --no-tree-shake-icons
```

## Codemagic Workflows
- android-release
- web-release
- windows-release
