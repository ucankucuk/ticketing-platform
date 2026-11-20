# ADR-0012: CNI olarak Cilium

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

kind'ın varsayılan CNI'ı kindnet NetworkPolicy uygulamıyor. Platformda servisler arası trafiğin kısıtlanması (Güvenlik bölümü) ve ağ trafiğinin görünürlüğü gerekiyor.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Cilium | eBPF; kube-proxy'nin yerini alır; L3-L7 network policy; Hubble ile trafik görünürlüğü; CNCF graduated | eBPF iç işleyişi öğrenme maliyeti |
| Calico | En yaygın CNI'lardan; olgun network policy; iptables veya eBPF modu | L7 politika ve görünürlük için ek bileşen |
| kindnet | Basit | NetworkPolicy uygulanmaz |

## Karar

Cilium kullanılır; kube-proxy kapatılır (kube-proxy replacement) ve Hubble etkinleştirilir. kind cluster'ı varsayılan CNI olmadan oluşturulur.

## Sonuçlar

NetworkPolicy'ler gerçekten uygulanır. Cluster yeniden oluşturulmalıdır.
