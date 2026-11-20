# ADR-0005: Yerel Kubernetes ortamı olarak kind

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Proje Kubernetes'i üretime yakın biçimde ve ileri özellikleriyle öğrenmeyi hedefliyor. Çoklu bölge ileride iki yerel cluster ile simüle edilecek.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| kind | Upstream Kubernetes (kubeadm), çok düğüm, CI'da en yaygın | Kalıcı depolama ve LoadBalancer için ek kurulum |
| k3d | Hafif ve hızlı | k3s bazı bileşenleri değiştirir; üretimden farklı |
| minikube | Olgun, zengin eklentiler | Ağır, yavaş açılış |
| Docker Desktop | Kolay kurulum | Tek düğüm |

## Karar

kind kullanılır: 1 control-plane ve farklı zone etiketli 3 worker. Aynı tanım CI'da smoke test olarak ayağa kaldırılır.

## Sonuçlar

Topology spread, anti-affinity, PDB ve düğüm arızası senaryoları yerelde denenebilir. CNI ve giriş kararları ayrı ADR'lerle verilecek.
