# ADR-0011: Arka ofis, kimlik alanları ve yetki modeli

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Platformu müşteri dışında platform yöneticileri, organizatör ekipleri, kapı görevlileri, müşteri hizmetleri ve finans kullanır.

## Seçenekler

| Konu | Seçilen | Alternatifler |
| --- | --- | --- |
| İş modeli | Hibrit (organizatör açar, platform onaylar) | Tam self-servis, yalnız platform ekibi |
| Arka ofis arayüzü | Ayrı uygulama + Admin BFF | Ortak Edge, aynı uygulama |
| Check-in | Çevrimdışı destekli mobil uygulama | Dönen barkod + online, yalnız online |
| Kimlik | Üç ayrı alan, çalışanlarda MFA | İki alan, tek alan |
| Yetki | Rol + kaynak kapsamı | ReBAC, OPA, yalnız RBAC |
| Kiracı izolasyonu | Ortak tablo + organizerId | Kiracı başına şema/veritabanı |
| Denetim | Tüm işlemler, değiştirilemez | Yalnız kritik işlemler, yok |

## Karar

Tablodaki seçilen seçenekler uygulanır; ayrıntılar mimari dokümanın Arka ofis bölümündedir.

## Sonuçlar

Admin BFF, Organizer, Access Control, Reporting ve Audit servisleri eklenir.
