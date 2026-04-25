---
agent: agent
description: Projeye uygun yeni bir Flutter ekranı scaffold eder — dosya, Provider bağlantısı ve route kaydı dahil.
---

# Yeni Flutter Ekranı Scaffold Et

Kullanıcıdan aldığın bilgileri aşağıdaki adımlarla uygula.

## Girdi
Oluşturulacak ekranın:
- **Adı** (ör. "ProfileDetail") — PascalCase
- **Amacı** — ne gösterecek/yapacak?
- **Hangi Provider'ları kullanacak** — mevcut: `UserProvider`, `TaskProvider`, `StatsProvider`
- **State gereksinimi** — StatefulWidget mi StatelessWidget mi? (UI state varsa StatefulWidget)

## Adımlar

### 1. Ekran Dosyasını Oluştur
`growth_tracker/lib/screens/<snake_case_name>_screen.dart` adıyla dosya oluştur.

**StatefulWidget şablonu:**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:growth_tracker/providers/<ilgili>_provider.dart';

class <PascalCase>Screen extends StatefulWidget {
  const <PascalCase>Screen({super.key});

  @override
  State<<PascalCase>Screen> createState() => _<PascalCase>ScreenState();
}

class _<PascalCase>ScreenState extends State<<PascalCase>Screen> {
  @override
  void initState() {
    super.initState();
    // Gerekiyorsa veri yükle
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<XProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('<Ekran Başlığı>')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : <içerik>,
    );
  }
}
```

### 2. Route Kaydı
`growth_tracker/lib/main.dart` veya router dosyasını incele. Ekrana uygun route ekle.  
Route adı: `/snake_case_name`

### 3. Navigasyon Erişimi
Mevcut bir ekrandan bu ekrana nasıl geçileceğini belirt. Örnek:
```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => const <PascalCase>Screen()));
```

### 4. Provider Bağlantısı
Kullanılacak her Provider için:
- `context.watch<XProvider>()` — reactive (build içinde)
- `context.read<XProvider>()` — action (callback içinde)
Doğrudan `Provider.of(context, listen: false)` kullanma.

### 5. Hata ve Loading State
```dart
if (provider.isLoading) return const Center(child: CircularProgressIndicator());
if (provider.error != null) return Center(child: Text(provider.error!));
```

## Kontrol Listesi
- [ ] Dosya adı `snake_case_screen.dart` formatında
- [ ] Sınıf adı `PascalCase` + `Screen` suffix
- [ ] Provider import'ları ekli
- [ ] `isLoading` ve `error` durumları ele alınmış
- [ ] Route kaydedilmiş
- [ ] Yeni import'lar mevcut dosyalara eklenmiş
