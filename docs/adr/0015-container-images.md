# ADR-0015: Dockerfile + buildx ile multi-arch imajlar ve GitHub Container Registry

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

Servislerin konteyner imajlarının nasıl üretileceği ve nerede tutulacağı seçilmeli. Yerel cluster arm64 (Apple Silicon), GitHub Actions runner'ları amd64.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Dockerfile + buildx | Evrensel beceri, tam kontrol; önyüzler için de aynı yöntem | Dockerfile bakımı |
| Jib | Docker daemon gerektirmez, hızlı | Yalnız Java |
| Buildpacks | Spring Boot'a gömülü, SBOM | En az kontrol |

## Karar

Her servis multi-stage Dockerfile ile, buildx kullanılarak amd64 ve arm64 için üretilir. İmajlar GitHub Container Registry'de (ghcr.io) tutulur.

## Sonuçlar

Aynı imaj hem CI'da hem yerel cluster'da çalışır.
