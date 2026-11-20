# ADR-0003: Build aracı olarak Maven

- **Durum:** Kabul edildi
- **Tarih:** 2026-11-18

## Bağlam

Çok modüllü bir monorepo için build aracı seçilmeli.

## Seçenekler

| Seçenek | Artı | Eksi |
| --- | --- | --- |
| Maven | Kurumsal standart, deklaratif, öngörülebilir | Çok modülde tekrar eden yapılandırma |
| Gradle (Kotlin DSL) | Incremental build ve build cache ile hızlı, esnek | Öğrenme eğrisi, betik karmaşıklığı |

## Karar

Maven kullanılır. Ortak yapılandırma kök `pom.xml`'de toplanır; Maven Enforcer Java 25 ve Maven 3.9+ şartını zorlar.

## Sonuçlar

Build süresi büyürse Maven build cache eklentisi değerlendirilir.
