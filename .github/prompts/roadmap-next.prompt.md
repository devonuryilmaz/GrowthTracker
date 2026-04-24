---
mode: agent
description: ROADMAP.md dosyasını inceler, tamamlanmamış maddeleri analiz eder ve bağımlılıklara göre en uygun sonraki geliştirme adımını önerir.
---

# Roadmap Analizi & Sonraki Geliştirme Önerisi

Aşağıdaki adımları sırasıyla uygula:

## 1. Roadmap'i Oku
`#file:ROADMAP.md` dosyasını oku. Tüm fazları ve iş kalemlerini incele:
- `[x]` ile işaretlenenler **tamamlandı**
- `[ ]` ile işaretlenenler **bekliyor**

## 2. Güncel Kod Durumunu Doğrula
Bekleyen maddeler için ilgili kaynak dosyaları kontrol et. Roadmap notlarıyla çelişen (daha ileri veya daha geri) gerçek bir durum varsa bunu belirt.

## 3. Bağımlılık Grafiğini Dikkate Al
ROADMAP'taki bağımlılık grafiğini kullan. Önerilecek adım:
- Tüm ön koşulları tamamlanmış olmalı
- Yüksek etki / düşük efor önceliğine sahip olmalı
- Mevcut kod mimarisini bozmadan uygulanabilir olmalı

## 4. Önerini Şu Formatta Sun

### ✅ Tamamlananlar (Özet)
Kaç faz ve kaç madde tamamlandığını kısa özetle.

### 🔴 Bekleyen Maddeler
Her bekleyen maddeyi faz numarasıyla listele. Kritik (engelleyici) olanları vurgula.

### 🎯 Önerilen Sonraki Adım
**FAZ X.Y — Başlık**

- **Neden bu adım?** Bağımlılıklar ve öncelik gerekçesi
- **Etkilenen dosyalar:** Düzenlenmesi gereken dosyaların listesi
- **Uygulama planı:** Numaralı, somut alt adımlar
- **Tahmini karmaşıklık:** Düşük / Orta / Yüksek
- **Riskler:** Dikkat edilmesi gereken yan etkiler

### 💡 Alternatif Seçenek
Önerilen adımı yapmak istemeyenler için bir alternatif faz ve kısa gerekçesi.
