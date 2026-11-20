# ADR-0010: Bekleme odasında sıralama stratejisi

- **Durum:** Kabul edildi (varsayım)
- **Tarih:** 2026-11-18

## Bağlam

Yoğun satışlarda kullanıcılar etkinlik/satış bazlı bekleme odalarına alınır. Sıralama yöntemi seçilmeli.

## Seçenekler

| Seçenek | Artı | Eksi | Sektörde |
| --- | --- | --- | --- |
| Katı FIFO | İlk gelen alır | Bot ve coğrafi yakınlık avantajı | SeatGeek, Cloudflare varsayılanı |
| Ön kuyruk rastgele + FIFO | Satış açılışında eşit şans | Açılış anında ilk gelen garantisi yok | Queue-it, Ticketmaster |

## Karar

Sıralama, oda bazında seçilebilen bir stratejidir. Varsayılan katı FIFO'dur.

## Sonuçlar

Bu karar kullanıcı cevabı olmadan varsayım olarak alındı; istenirse değiştirilir.
