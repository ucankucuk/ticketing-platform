# ADR-0016: Gözlemlenebilirlik için OpenTelemetry ve Grafana yığını

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

Log, metrik ve trace için bir yığın seçilmeli. Servisler telemetriyi OpenTelemetry standardıyla üretecek.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| OTel + Prometheus, Loki, Tempo, Grafana | Açık kaynakta en yaygın; her bileşen ayrı öğrenilir | Birden fazla bileşen |
| OTel + Elastic | Kurumsal ortamlarda yaygın | Ağır, çok bellek |
| OTel + SigNoz | Tek üründe her şey | Sektörde daha az yaygın |

## Karar

OpenTelemetry Collector telemetriyi toplar; metrikler Prometheus, loglar Loki, trace'ler Tempo'da tutulur; arayüz Grafana'dır.

## Sonuçlar

Servisler yalnızca OTel'e bağımlıdır; arka uç değişirse servis kodu değişmez.
