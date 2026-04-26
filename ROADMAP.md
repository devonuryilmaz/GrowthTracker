# GrowthTracker — Yol Haritası & İş Takip Dokümanı

> **Vizyon:** Her meslek grubuna hitap eden, AI destekli Kişisel Gelişim Koçu.  
> **Son Güncelleme:** 26 Nisan 2026 (v5)

---

## 📊 Mevcut Durum Analizi

### Backend (.NET 9 + PostgreSQL + Hangfire + Firebase)
| Bileşen | Durum | Not |
|---------|-------|-----|
| User entity | ✅ Var | `Name`, `Job`, `Age`, `FocusArea` — tam |
| DailyTask entity | ✅ Var | `Title`, `Description`, `IsCompleted`, `UserId`, `Category`, `EstimatedMinutes`, `IsSelected`, `CompletedAt` — tam |
| OpenAI entegrasyonu | ✅ Var | Türkçe 3'lü JSON Array döndürüyor; `GenerateTaskSuggestionsAsync` + `GenerateTaskExamplesAsync` (4 örnek) |
| AIGeneratorJob (Hangfire) | ✅ Aktif | Günlük çalışıyor, 3 görev kaydediyor, idempotent kontrol var |
| ReminderJob | ✅ Aktif | Program.cs'de aktif, gerçek DeviceToken tablosundan çekiyor |
| UsersController | ✅ Var | `POST /api/users/sync` ve `GET /api/users/{id}` endpoint'leri mevcut |
| AIController | ✅ Var | `GET /api/ai/suggestions` + yeni `GET /api/ai/task-examples?taskId&userId` endpoint'i |
| DailyTasksController | ✅ Var | `today`, `select`, `complete`, `history`, `stats`, `from-suggestion` — tam |
| TaskSelection yapısı | ✅ Var | Entity, endpoint ve servis tam olarak implement edildi |
| Görev tamamlama endpoint'i | ✅ Var | `POST /api/dailytasks/{id}/complete` çalışıyor |
| IUserService | ✅ Tam | `Create`, `GetById`, `Update`, `GetOrCreate` metotları var |
| NotificationService/FirebaseService | ⚠️ Ayrı | İki servis hâlâ ayrı; `NotificationService` dead code (`"YOUR_SERVER_KEY"` hardcoded), birleştirme yapılmadı (FAZ 4.5) |

### Flutter (Dart)
| Bileşen | Durum | Not |
|---------|-------|-----|
| Login/Onboarding | ✅ Var | Ad, Yaş, Meslek, Odak Alanı (6 kategori) — çok adımlı |
| Home Screen | ✅ Var | Selamlama, aktif görev kartı, geri sayım timer, tamamlama butonu |
| Task Detail Screen | ✅ Yeni | `TaskDetailScreen` — AI örnekleri (`task-examples` endpoint), görev detayı, "Başla" butonu |
| AddReminder Screen | ⚠️ Orphaned | Ekran mevcut ama `MainShell`'e bağlı değil — erişilemiyor |
| State Management | ✅ Var | `provider` paketi, `UserProvider` + `TaskProvider` + `StatsProvider` |
| User modeli | ✅ Var | `lib/models/user_model.dart` — tam model |
| DailyTask / AI Task modeli | ✅ Var | `lib/models/daily_task.dart`, `lib/models/task_selection.dart` |
| Task Discovery ekranı | ✅ Var | 3 TaskCard, shimmer yükleme, seçim → TaskDetail → Home yönlendirme |
| Aktif Görev paneli | ✅ Var | HomeScreen'de geri sayım timer ile aktif görev paneli |
| Journey / Stats ekranı | ✅ Tam | `table_calendar` + `fl_chart` entegre edildi; `BarChart` (haftalık), `PieChart` donut (kategori dağılımı), renkli takvim |
| Ayarlar ekranı | ✅ Var | Profil düzenleme var; bildirim/dark mode toggle'ları `SharedPreferences`'a persist ediliyor |
| Backend'e user sync | ✅ Var | Onboarding ve Settings'ten `POST /api/users/sync` çağrılıyor |
| DeviceToken kaydı | ✅ Düzeltildi | `sendTokenToServer` `userId` guard ile korunuyor; token SharedPrefs'e kaydedilip kullanıcı yüklendikten sonra gönderiliyor |
| Görev tamamlama feedback | ✅ Var | `confetti` paketi eklendi, `ConfettiController` + `ConfettiWidget` `home.dart`'ta entegre edildi |
| Named Routes | ⚠️ Eksik | `MaterialPageRoute` kullanılıyor, `MaterialApp.routes` tanımlanmadı |
| Flutter NotificationService | ⚠️ Unused | `lib/services/notification_service.dart` mevcut ama hiçbir yerden çağrılmıyor |

---

## 🗺️ Fazlar & İş Kalemleri

---

### FAZ 1 — Backend Veri Modeli & API Temeli
> **Hedef:** AI'ın 3 görev üretip kullanıcıya sunabilmesi için backend altyapısını hazırla.

- [x] **1.1** `User` entity'ye `FocusArea` (string) alanı ekle
- [x] **1.2** `DailyTask` entity'yi genişlet:
  - `UserId` (Guid, FK → User)
  - `Category` (string — Kariyer, Sağlık, Zihin vb.)
  - `EstimatedMinutes` (int)
  - `IsSelected` (bool — kullanıcı bu görevi seçti mi)
  - `CompletedAt` (DateTime? — tamamlanma zamanı)
- [x] **1.3** `TaskSelection` entity oluştur:
  - `Id`, `UserId`, `DailyTaskId`, `SelectedAt`, `CompletedAt`, `Status` (Pending/Active/Completed/Skipped)
- [x] **1.4** Migration oluştur ve uygula *(oluşturulan migration: `20260417060000_UpdateModel` — tüm entity değişikliklerini kapsamaktadır)*
- [x] **1.5** `AppDbContext`'e yeni DbSet'leri ekle, FK ilişkilerini `OnModelCreating` ile tanımla

---

### FAZ 2 — Backend API Endpoint'leri
> **Hedef:** Flutter'ın ihtiyaç duyduğu tüm CRUD + iş mantığı endpoint'lerini aç.

- [x] **2.1** `UsersController` — Kullanıcı senkronizasyon endpoint'leri:
  - `POST /api/users/sync` — Upsert (yoksa oluştur, varsa güncelle: Name, Job, Age, FocusArea)
  - `GET /api/users/{id}` — Kullanıcı bilgilerini getir
- [x] **2.2** `IUserService` + `UserService`'e `UpdateUser` ve `GetOrCreateUser` metotları ekle
- [x] **2.3** `AIController` — Görev önerileri:
  - `GET /api/ai/suggestions?userId={id}` → 3 görev içeren JSON Array döndür
  - `GET /api/ai/task-examples?taskId={id}&userId={id}` → Seçilen görev için 4 somut örnek döndür *(yeni)*
- [x] **2.4** `DailyTasksController` — Görev seçim & tamamlama:
  - `GET /api/dailytasks/today?userId={id}` — Kullanıcının bugünkü 3 önerisini getir
  - `POST /api/dailytasks/{id}/select` — Kullanıcının seçtiği görevi işaretle
  - `POST /api/dailytasks/{id}/complete` — Görevi tamamlandı olarak işaretle
  - `GET /api/dailytasks/history?userId={id}&days=30` — Geçmiş tamamlanan görevler
- [x] **2.5** Completion istatistik endpoint'i:
  - `GET /api/dailytasks/stats?userId={id}` — Kategoriye göre tamamlanan görev sayıları
- [x] **2.6** `POST /api/dailytasks/from-suggestion` — AI önerisinden direkt görev oluştur *(yeni)*

---

### FAZ 3 — OpenAI Prompt Revizyonu & AI Job Güncellemesi
> **Hedef:** AI'ın 3 farklı kategoride, yapılandırılmış JSON formatında görev üretmesini sağla.

- [x] **3.1** `OpenAIService.GenerateTaskSuggestionsAsync` prompt'unu revize et:
  - Kullanıcının `FocusArea`'sını prompt'a dahil et
  - 3 farklı kategoride görev iste (ör. kullanıcının odak alanı + 2 tamamlayıcı)
  - Çıktı formatı: JSON Array `[{title, description, category, estimatedMinutes}]`
  - `response_format: json_object` parametresini kullan
  - MaxOutputTokenCount'u 200'den ~600'e çıkar
- [x] **3.2** `OpenAIService`'in dönüş tipini `string` → `List<TaskSuggestionDto>` DTO'ya çevir
- [x] **3.3** `AIGeneratorJob.GenerateTasksAsync` güncelle:
  - Her kullanıcı için 3 `DailyTask` kaydı oluştur (UserId, Category, EstimatedMinutes ile)
  - Aynı gün için mükerrer üretimi engelle (idempotent kontrol)
- [x] **3.4** AI endpoint'i (`GET /api/ai/suggestions`) doğrudan JSON Array döndürecek şekilde güncelle

---

### FAZ 4 — ReminderJob Aktivasyonu & Push Notification
> **Hedef:** Seçilen görevin zamanı geldiğinde gerçek push notification gönder.

- [x] **4.1** `ReminderJob`'daki hardcoded `"TEST_TOKEN"`'ı kaldır; kullanıcının `DeviceToken` tablosundan gerçek token'ı çek
- [x] **4.2** `Program.cs`'deki ReminderJob recurring job kaydını aktif hale getir (yorum satırından çıkar)
- [x] **4.3** Görev seçildiğinde o görev için otomatik bir `Reminder` kaydı oluştur (veya doğrudan `TaskSelection` üzerinden bildirim gönder)
- [x] **4.4** Bildirim içeriğini zenginleştir: görev başlığı, süre, motivasyon mesajı
- [x] **4.5** `NotificationService` (legacy FCM HTTP v1) silindi; `RemindersController` `IFirebaseService` (Admin SDK) zaten kullanan `ReminderJob` ile uyumlu hale getirildi *(dead code temizlendi)*

---

### FAZ 5 — Flutter: Veri Modelleri & State Management Altyapısı
> **Hedef:** Tüm ekranların üzerinde çalışacağı modeller ve state yönetim katmanını kur.

- [x] **5.1** Flutter modelleri oluştur:
  - `User` (id, name, job, age, focusArea)
  - `DailyTask` / `TaskSuggestion` (id, title, description, category, estimatedMinutes, isSelected, isCompleted)
  - `TaskSelection` (id, taskId, selectedAt, completedAt, status)
- [x] **5.2** `pubspec.yaml`'a `provider` (veya tercih edilen state management) paketini ekle
- [x] **5.3** Provider/ChangeNotifier sınıfları oluştur:
  - `UserProvider` — kullanıcı profili, backend sync
  - `TaskProvider` — günlük görevler, seçim, tamamlama
  - `StatsProvider` — istatistik verileri
- [x] **5.4** `ApiService`'e yeni endpoint çağrılarını ekle:
  - `syncUser()`, `fetchSuggestions()`, `selectTask()`, `completeTask()`, `fetchHistory()`, `fetchStats()`
- [x] **5.5** `main.dart`'ta `MultiProvider` ile provider'ları sar

---

### FAZ 6 — Flutter: Onboarding Akışı Yenileme
> **Hedef:** Kullanıcıyı tanıyarak kişiselleştirilmiş deneyim sun.

- [x] **6.1** `LoginScreen`'i çok adımlı onboarding'e dönüştür:
  - **Adım 1:** Hoş geldin + İsim girişi
  - **Adım 2:** Yaş + Meslek
  - **Adım 3:** "Gelişim Odak Alanı" seçim ekranı (görsel ikonlarla grid)
    - 🏃‍♂️ Sağlık & Fitness
    - 💼 Kariyer & Üretkenlik
    - 🧠 Zihinsel Gelişim
    - 📚 Öğrenme & Beceri
    - 🧘 Mindfulness & Stres
    - 💰 Finansal Okuryazarlık
- [x] **6.2** Onboarding tamamlandığında backend'e `POST /api/users/sync` çağrısı yap
- [x] **6.3** Kullanıcı bilgilerini hem `SharedPreferences`'a hem `UserProvider`'a kaydet
- [x] **6.4** İlk kullanım kontrolü: `SharedPreferences`'ta user yoksa → Onboarding, varsa → Home

---

### FAZ 7 — Flutter: Task Discovery Ekranı (Görev Seçimi — "Aha!" Anı)
> **Hedef:** AI'ın ürettiği 3 görev kartını sunarak kullanıcıya otonomi hissi ver.

- [x] **7.1** `TaskDiscoveryScreen` oluştur:
  - Üst başlık: "Bugün senin için hazırladık ✨"
  - 3 adet `TaskCard` widget'ı (swipeable veya scrollable)
  - Her kartta:
    - Kategori ikonu + renk kodu
    - Görev Başlığı (bold)
    - Kısa Açıklama (2-3 satır)
    - ⏱ Tahmini Süre badge'i
    - "Seç ve Başla" butonu
- [x] **7.2** Kart seçildiğinde `POST /api/dailytasks/{id}/select` çağrısı
- [x] **7.3** Seçim sonrası Home Screen'e yönlendir
- [x] **7.4** Görev önerileri yüklenmemişse veya yeni gün başlamışsa `GET /api/ai/suggestions` tetikle
- [x] **7.5** Yükleme durumu için shimmer/skeleton animasyonu

---

### FAZ 8 — Flutter: Home Screen (Aktif Görev Paneli)
> **Hedef:** Kullanıcının aktif görevini her açılışta görüp tamamlayabildiği ana ekran.

- [x] **8.1** `HomeScreen`'i yeniden tasarla:
  - **Üst alan:** Selamlama ("Günaydın, {isim}! 👋") + tarih ✅
  - **Ana kart:** Seçilen aktif görevin detayı (başlık, açıklama, kategori, süre) ✅
  - **Geri sayım timer:** `estimatedMinutes * 60` saniye sayaç ✅
  - **"Tamamladım" butonu** — tıklandığında:
    - `POST /api/dailytasks/{id}/complete` çağrısı ✅
    - Konfeti animasyonu (confetti package) ✅ *`confetti` paketi eklendi, `home.dart`'ta entegre edildi*
    - Tebrik mesajı ✅
  - **Alt alan:** Günlük progress bar (tamamlanan / toplam) ✅
- [x] **8.2** Henüz görev seçilmemişse → Task Discovery'e yönlendir
- [x] **8.3** Gün içinde görev tamamlandıysa → "Harika iş! Yarın yeni görevler seni bekliyor" durumu
- [x] **8.4** Pull-to-refresh ile güncel veri çekme

---

### FAZ 9 — Flutter: Journey / Stats Ekranı (Gelişim Geçmişi)
> **Hedef:** Kullanıcının geçmiş performansını görselleştirerek motivasyon sağla.

- [x] **9.1** `JourneyScreen` oluştur:
  - **Takvim görünümü:** Tamamlanan günler işaretli (streak/seri desteği) ✅ *`table_calendar` ile `eventLoader` + `calendarBuilders` + renkli dot'lar entegre edildi*
  - **Liste görünümü:** Geçmiş görevler tarih sıralı ✅
  - Takvim/liste arasında toggle ✅ *(görünüm toggle'ı mevcut)*
- [x] **9.2** Kategori bazlı istatistik grafikleri:
  - Pasta grafik veya bar chart (fl_chart paketi) ✅ *`fl_chart: ^0.69.2` eklendi; `_WeeklyBarChart` → `BarChart`, `_CategoryDonutChart` → `PieChart` donut*
  - Kariyer: X görev, Sağlık: Y görev vb. ✅
- [x] **9.3** Toplam tamamlama sayısı, en uzun seri, bu haftaki performans gibi özet kartlar
- [x] **9.4** `GET /api/dailytasks/history` ve `GET /api/dailytasks/stats` entegrasyonu

---

### FAZ 10 — Flutter: Reminder & Settings Ekranı (Ayarlar)
> **Hedef:** Kullanıcının bildirim ve profil tercihlerini yönetebileceği ekran.

- [x] **10.1** `SettingsScreen` oluştur:
  - **Bildirim Zamanlayıcı:** Günlük görev hatırlatma saati seçimi (TimePicker)
  - **Profil Düzenleme:** Ad, Yaş, Meslek, Odak Alanı güncelleme
  - Değişiklikler kaydedildiğinde `POST /api/users/sync` çağrısı
- [x] **10.2** Bildirim açma/kapama toggle'ı *(UI var, ancak persist edilmiyor — bkz. eksik iş)*
- [x] **10.3** Seçilen hatırlatma saatini backend'e kaydet (Reminder veya User preferences)
- [x] **10.4** Hakkında / Versiyon bilgisi

---

### FAZ 11 — Flutter: Navigasyon & Genel UX
> **Hedef:** Tüm ekranları bir arada tutan navigasyon yapısını kur.

- [x] **11.1** Bottom Navigation Bar ekle:
  - 🏠 Home (Aktif Görev)
  - 🔍 Discover (Görev Seçimi)
  - 📊 Journey (İstatistik)
  - ⚙️ Settings (Ayarlar)
- [ ] **11.2** `MaterialApp`'e named routes tanımla *(hâlâ `MaterialPageRoute` ile doğrudan navigasyon kullanılıyor)*
- [x] **11.3** Uygulama teması (ThemeData) — tutarlı renk paleti, tipografi, kart stilleri (`app_theme.dart`)
- [x] **11.4** Splash screen + ilk yükleme akışı (auth check → onboarding / home)
- [ ] **11.5** Hata durumları için genel error widget'ları
- [x] **11.6** `AddReminderScreen` projeden kaldırıldı *(ekran silindi — bildirim yönetimi Settings ekranına taşındı)*

---

### FAZ 13 — Home Screen: Boş Durum İyileştirmesi
> **Hedef:** Görev seçilmemişken Home ekranını anlamlı ve motive edici hale getir.

- [x] **13.1** Boş durum için zengin bir karşılama ekranı tasarla:
  - Kullanıcıya özel selamlama + günün tarihi
  - Mevcut streak bilgisi ve toplam tamamlama sayısı
  - Kategori ikonlarıyla "Bugün hangi alanda çalışmak istersin?" yönlendirme kartı
- [x] **13.2** Öne çıkan "Görevleri Keşfet" CTA butonu — tıklayınca Discovery ekranına götürsün
- [x] **13.3** Motivasyonel günlük söz veya ipucu kartı (statik veya rotasyonlu)
- [x] **13.4** Mini istatistik widget: "Bu hafta X görev tamamladın 🎉"

---

### FAZ 14 — Günlük 3 Görev (Sıralı Tamamlama)
> **Hedef:** Kullanıcı günde max 3 görev tamamlayabilsin; ancak aynı anda tek görev seçilip tamamlandıktan sonra sıradaki seçilebilsin (odak prensibi).

- [x] **14.1** Backend — `POST /api/dailytasks/{id}/select`:
  - Bugün tamamlanan görev sayısı ≥ 3 → `400 BadRequest` (yeni seçime izin verme)
  - Mevcut `Active` seçim varsa `Skipped` yap (tek aktif görev prensibi korunuyor)
  - Aynı görev zaten `Active` ise idempotent `200 OK`
- [x] **14.2** Backend — `POST /api/dailytasks/from-suggestion`: Aynı limit kontrolü eklendi
- [x] **14.3** `TaskProvider` güncellendi:
  - `activeTask` tekil yapısı korundu
  - Yeni getter: `int get completedTodayCount` — bugün tamamlanan görev sayısı
  - Yeni getter: `bool get canSelectMore` — `completedTodayCount < 3`
  - `completeTask`: Yerel `completedAt` timestamp'i de set ediyor
- [x] **14.4** `HomeScreen` güncellendi:
  - Görev tamamlandıktan sonra `canSelectMore == true` → "Sıradaki Görevi Seç" CTA + "X/3 tamamlandı" bilgisi
  - `canSelectMore == false` → "Günlük Hedef Tamamlandı 🎉" ekranı (3/3)
- [x] **14.5** `TaskDiscoveryScreen` güncellendi:
  - Üst badge: "Bugün X/3 görev tamamlandı" (tamamlama sayacı)
  - `canSelectMore == false` iken seçim girişiminde Snackbar uyarısı
- [ ] **14.6** Migration: `DailyTask.IsSelected` boolean korunuyor; `SelectionOrder` eklenmedi (sequential model ile gereksiz)

---

### FAZ 15 — Journey: Renkli Kategorili Takvim
> **Hedef:** Takvimde tamamlanan görevleri kategorilerine göre renkli dot'larla göster.

- [x] **15.1** `table_calendar` paketini `pubspec.yaml`'a ekle
- [x] **15.2** Her kategori için sabit renk kodu tanımla (helper/constants dosyasına):
  - 🔴 Sağlık & Fitness
  - 🔵 Kariyer & Üretkenlik
  - 🟣 Zihinsel Gelişim
  - 🟠 Öğrenme & Beceri
  - 🟢 Mindfulness & Stres
  - 🟡 Finansal Okuryazarlık
- [x] **15.3** `JourneyScreen` takvim görünümünü `table_calendar` ile implemente et:
  - Tamamlanan her güne kategorisine göre renkli dot(lar) ekle
  - Birden fazla kategori aynı günde tamamlandıysa birden fazla dot
  - Takvim günlerine tıklandığında o günün görev listesi alt panelde açılsın
- [x] **15.4** `GET /api/dailytasks/history` response'una `category` alanı dahil edildiğini doğrula (zaten var, frontend'de kullanılmalı)
- [x] **15.5** Renk efsanesi (legend) widget'ı ekle — hangi renk hangi kategori

---

### FAZ 16 — Kullanıcı Kimlik Doğrulama (Firebase Auth)
> **Hedef:** Kullanıcı verilerini cihaz bağımsız hale getir; uygulama silinse veya cihaz değişse veriler korunsun.

- [ ] **16.1** Flutter: `firebase_auth` paketini ekle
- [ ] **16.2** Google Sign-In entegrasyonu:
  - `google_sign_in` paketi ekle
  - `LoginScreen`'e "Google ile Devam Et" butonu ekle
  - Firebase Auth'dan `uid` al
- [ ] **16.3** Apple Sign-In entegrasyonu (iOS zorunlu):
  - `sign_in_with_apple` paketi ekle
  - iOS entegrasyon ayarları (Capabilities, entitlements)
- [ ] **16.4** Onboarding akışını Auth'a bağla:
  - Yeni kullanıcı: Auth → Onboarding (isim/yaş/meslek/odak) → backend sync
  - Dönüş kullanıcısı: Auth → direkt Home
  - Firebase `uid` → backend `User.Id` (Guid) eşlemesi için `UsersController` güncelle
- [ ] **16.5** Backend: `UserSyncRequest`'e `FirebaseUid` (string) alanı ekle; `GetOrCreateUser`'ı uid ile de arayabilecek şekilde güncelle
- [ ] **16.6** `SharedPreferences`'taki `userId` → Firebase `uid` ile senkron tut
- [ ] **16.7** Logout: Firebase Auth sign-out + SharedPreferences temizle
- [ ] **16.8** `sendTokenToServer` null userId sorununu bu fazda çöz — Auth sonrası uid mevcut olacak

---

### FAZ 12 — Entegrasyon Testleri & Son Dokunuşlar
> **Hedef:** Uçtan uca akışların doğru çalıştığından emin ol.

- [ ] **12.1** Backend integration testleri: AI endpoint, Task CRUD, User sync
- [ ] **12.2** Flutter widget testleri: Onboarding akışı, Task Discovery, Home Screen
- [x] **12.3** `confetti` ✅, `table_calendar` ✅, `fl_chart` ✅ — üç paket de pubspec'e eklendi ve entegre edildi
- [ ] **12.4** Uçtan uca test: Onboarding → AI suggestion → Task select → Complete → Stats görüntüleme
- [x] **12.5** README.md güncellemesi: Yeni mimari, kurulum adımları, ekran görüntüleri
- [x] **12.6** Settings ekranındaki bildirim/dark-mode toggle'larını persist et (SharedPreferences)
- [x] **12.7** `sendTokenToServer` null userId sorununu düzelt — token kaydı kullanıcı giriş sonrasına taşı

---

## 🔄 Bağımlılık Grafiği

```
FAZ 1 (Entity Modeli)
  └──→ FAZ 2 (API Endpoint'leri)
        ├──→ FAZ 3 (AI Prompt Revizyonu)
        │     └──→ FAZ 4 (ReminderJob Aktivasyonu)
        └──→ FAZ 5 (Flutter State & Model)
              ├──→ FAZ 6 (Onboarding)
              ├──→ FAZ 7 (Task Discovery)
              ├──→ FAZ 8 (Home Screen)
              ├──→ FAZ 9 (Journey / Stats)
              └──→ FAZ 10 (Settings)
                    └──→ FAZ 11 (Navigasyon & UX)
                          └──→ FAZ 12 (Test & Polish)

Yeni fazlar (bağımsız geliştirilebilir):
FAZ 13 (Home Boş Durum) — FAZ 8 tamamlandıktan sonra
FAZ 14 (3 Görev Seçimi) — Backend FAZ 2 + Flutter FAZ 5 tamamlandıktan sonra
FAZ 15 (Renkli Takvim) — FAZ 9 tamamlandıktan sonra
FAZ 16 (Firebase Auth) — FAZ 6 (Onboarding) tamamlandıktan sonra; FAZ 14 ve 12.7 ile paralel
```

**Paralel çalışılabilir:**
- FAZ 1–4 (Backend) ↔ FAZ 5 (Flutter modeller & state) aynı anda başlayabilir (mock data ile)
- FAZ 7, 8, 9, 10 birbirinden bağımsız geliştirilebilir (FAZ 5 tamamlandıktan sonra)

---

## 📦 Eklenecek Flutter Paketleri

| Paket | Amaç | Durum |
|-------|------|-------|
| `provider` | State management | ✅ Eklendi |
| `google_fonts` | Tipografi | ✅ Eklendi |
| `shared_preferences` | Yerel veri saklama | ✅ Eklendi |
| `device_info_plus` | Cihaz ID alımı (FCM token kayıt) | ✅ Eklendi |
| `firebase_core` + `firebase_messaging` | Push notification | ✅ Eklendi |
| `flutter_local_notifications` | Yerel bildirim (kullanılmıyor) | ✅ Eklendi ama unused |
| `intl` | Tarih formatlama | ✅ Eklendi |
| `fl_chart` | İstatistik grafikleri | ✅ Eklendi |
| `confetti` | Görev tamamlama kutlama animasyonu | ✅ Eklendi |
| `table_calendar` | Takvim görünümü (Journey) | ✅ Eklendi |
| `shimmer` | Yükleme placeholder animasyonları | ❌ Eklenmedi |
| `smooth_page_indicator` | Onboarding adım göstergesi | ❌ Eklenmedi |
| `firebase_auth` | Kullanıcı kimlik doğrulama (FAZ 16) | ❌ Eklenmedi |
| `google_sign_in` | Google ile giriş (FAZ 16) | ❌ Eklenmedi |
| `sign_in_with_apple` | Apple ile giriş (FAZ 16, iOS) | ❌ Eklenmedi |

---

## 📦 Eklenecek Backend NuGet Paketleri

| Paket | Amaç |
|-------|------|
| — | Mevcut paketler yeterli (OpenAI, Hangfire, EF Core, Firebase Admin) |

---

## 📝 Notlar

- **CORS:** `AllowAll` politikası development için uygun, production'da kısıtlanmalı.
- **NotificationService kaldırıldı:** `NotificationService.cs` silindi, `RemindersController` bağımlılığı temizlendi, `Program.cs` kaydı kaldırıldı. `FirebaseService` (Admin SDK) geçerli bildirim servisi.
- **Flutter notification_service.dart:** `lib/services/notification_service.dart` mevcut ama `main.dart` veya hiçbir provider'dan çağrılmıyor — dead code.
- **DeviceToken null userId:** `main.dart`'taki `sendTokenToServer` fonksiyonu `userId: null` gönderiyor. `ReminderJob` device token'ı kullanıcıya göre sorgulayacağından push notification çalışmaz. Token kaydı, kullanıcı `SharedPreferences`'tan yüklendikten sonra yapılmalı.
- **AddReminderScreen kaldırıldı:** Ekran projeden silindi; bildirim yönetimi Settings ekranında kalıyor.
- **Namespace typo:** `DailyTasksController` ve `DeviceTokenController` dosyalarında `GrowtTracker.API.Controllers` namespace'i yazılmış (`GrowthTracker` yerine `GrowtTracker`).
- **AI Prompt dili:** OpenAI prompt'u Türkçe görev üretiyor (`gpt-4o`). Dil tercihi gelecekte eklenebilir.
- **baseUrl hardcoded:** Flutter'da `http://localhost:5058/api` olarak sabit; fiziksel cihazda veya prod'da çalışmaz. Ortama göre konfigüre edilmeli.
- **IOpenAIService yok:** `OpenAIService` direkt injection ile kullanılıyor; test edilebilirlik için interface eklenebilir.
