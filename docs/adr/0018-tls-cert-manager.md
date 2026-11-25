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

- cert-manager v1.21.3, Jetstack Helm chart'ıyla Argo CD üzerinden kurulur (`deploy/argocd/apps/cert-manager.yaml`, değerler `platform/cert-manager/values.yaml`). CRD'ler chart ile gelir.
- CA zinciri ayrı bir Application'dadır (`platform/cert-manager/issuers`): `selfsigned-bootstrap` ClusterIssuer'ı kök CA sertifikasını (`local-ca-root`) imzalar; `local-ca` ClusterIssuer'ı bu CA ile uygulama sertifikalarını imzalar.
- Sertifika isteyen her kaynak `issuerRef` olarak `local-ca` ClusterIssuer'ını kullanır.

## Sonuçlar

Gateway sertifikaları cert-manager tarafından otomatik üretilir ve yenilenir.
