# ADR-0013: Cluster girişi için Gateway API ve Envoy Gateway

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-21

## Bağlam

Dış trafiğin cluster'a girişi için bir uygulama seçilmeli. Ingress NGINX Mart 2026'da emekliye ayrıldı; Kubernetes topluluğu Gateway API'ye yönlendiriyor.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Envoy Gateway | Envoy'un resmi Gateway API uygulaması; standarda sadık, bağımsız | Ayrı bir bileşen |
| Cilium Gateway | Cilium seçildiği için ek bileşen yok | Özellik kapsamı daha dar |
| Istio Gateway | Mesh gelirse aynı araç | Tek başına giriş için ağır |
| NGINX Gateway Fabric | NGINX deneyimi olan ekipler için tanıdık | Envoy ekosistemi dışında |

## Karar

Gateway API kaynakları (GatewayClass, Gateway, HTTPRoute) ve Envoy Gateway kullanılır. Ingress API kullanılmaz.

## Sonuçlar

Uygulamaya özel annotation bağımlılığı olmaz; yönlendirme kuralları taşınabilir kalır.
