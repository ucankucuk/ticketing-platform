# ADR-0002: Java 25 ve Spring Boot 4

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Uygulama dili ve framework'ü seçilmeli. Spring Boot 3.5'in açık kaynak desteği Haziran 2026'da bitti; Spring Boot 4, Java 17-25 aralığını destekliyor.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Java 25 + Spring Boot 4 | En güncel LTS, virtual thread ve yeni dil özellikleri | Bazı kütüphanelerin uyumu gecikebilir |
| Java 21 + Spring Boot 4 | Kurumsal projelerde daha yaygın | Yeni özelliklerden yararlanılamaz |

## Karar

## Karar

Java 25 ve Spring Boot 4.2.0 kullanılır. Yeni yama ve minor sürümler Dependabot PR'larıyla takip edilir.

## Sonuçlar

Sürümler Dependabot ile güncel tutulur. Bir kütüphane Java 25 ile uyumsuz çıkarsa ayrı ADR ile ele alınır.
