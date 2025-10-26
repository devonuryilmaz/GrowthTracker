# Growth Tracker - Flutter App

Growth Tracker uygulamasının Flutter frontend kısmıdır. Kişisel gelişim hatırlatıcılarınızı yönetmenizi sağlar.

## Bu Proje Hakkında

Bu Flutter uygulaması, Growth Tracker sisteminin mobil arayüzüdür. .NET Core backend API'si ile iletişim kurarak hatırlatıcı verilerini alır ve yönetir.

## Özellikler

- 📋 Hatırlatıcı listesi görüntüleme
- ➕ Yeni hatırlatıcı ekleme
- 🔄 Pull-to-refresh ile veri yenileme
- ⚡ Gerçek zamanlı API entegrasyonu

## Dosya Yapısı

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── models/
│   └── reminder.dart           # Reminder model sınıfı
├── screens/
│   ├── home.dart              # Ana sayfa widget'ı
│   └── add_reminder_screen.dart # Hatırlatıcı ekleme sayfası
└── services/
    └── api_service.dart       # Backend API iletişim servisi
```

## Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK 3.0+
- Backend API'nin çalışır durumda olması (localhost:5058)

### Adımlar

1. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

2. **Backend API'nin çalıştığından emin olun:**
   - Backend API localhost:5058 portunda çalışmalı
   - API endpoints: `/api/reminders/upcoming` ve `/api/reminders`

3. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

## API Bağlantısı

Uygulama aşağıdaki endpoint'leri kullanır:
- `GET /api/reminders/upcoming` - Hatırlatıcıları getir
- `POST /api/reminders` - Yeni hatırlatıcı ekle

API base URL: `http://localhost:5058/api`

## Kullanım

1. Uygulama açıldığında mevcut hatırlatıcılar listelenir
2. Sağ alt köşedeki + butonuna tıklayarak yeni hatırlatıcı ekleyebilirsiniz
3. Listeyi yenilemek için sayfayı aşağı çekin
4. Yeni hatırlatıcı ekledikten sonra ana sayfaya döndüğünüzde liste otomatik güncellenir

## Geliştirme

```bash
# Debug modunda çalıştır
flutter run --debug

# Hot reload için r'ye basın
# Hot restart için R'ye basın
```

## Lisans

Bu proje MIT lisansı ile lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakabilirsiniz.
