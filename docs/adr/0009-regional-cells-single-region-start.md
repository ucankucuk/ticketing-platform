# ADR-0009: Hücre modeline hazır tasarım, tek bölgeyle başlangıç

- **Durum:** Kabul edildi (varsayım)
- **Tarih:** 2026-11-18

## Bağlam

Platform global olacak. Dağıtım modeli seçenekleri: tek bölge + CDN, aktif-pasif, bölgesel hücreler, global aktif-aktif.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Hücreye hazır, tek bölgeyle başla | Veri modeli baştan doğru; fazlar yavaşlamaz | İkinci bölge sonradan eklenir |
| Baştan iki bölge | En gerçekçi | Her faz yavaşlar |
| Tek bölge, hücre yok | En basit | Çoklu bölge büyük değişiklik olur |

## Karar

Veri modeli ve yönlendirme bölgesel hücre modeline göre tasarlanır (ev bölgesi, bölge alanları). Proje tek bölgeyle başlar, ikinci bölge Faz 8'de eklenir.

## Sonuçlar

Bu karar kullanıcı cevabı olmadan varsayım olarak alındı; istenirse değiştirilir.
