# ADR-0018: TLS için cert-manager ve yerel CA

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

Yerelde HTTPS, Secure cookie ve OIDC akışlarının gerçekçi çalışması için TLS gerekiyor.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| cert-manager + yerel CA | Kubernetes'te sektör standardı; üretimde aynı kaynaklarla Let's Encrypt | Yerel CA'nın tarayıcıya güvenilir olarak eklenmesi gerekir |
| Yerelde TLS yok | Basit | HTTPS ve OIDC akışları gerçekçi test edilemez |

## Karar

cert-manager kullanılır; yerelde kendi CA'mız (ClusterIssuer) sertifika üretir.

## Sonuçlar

Gateway sertifikaları cert-manager tarafından otomatik üretilir ve yenilenir.
