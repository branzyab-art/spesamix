# SpesaMix

App Flutter per Android e iPhone che permette di inserire prodotti acquistati e visualizzare la percentuale di:

- Bibite
- Cibo salato
- Cibo dolce

## Funzioni

- Inserimento nome prodotto
- Scelta categoria
- Quantità e unità (pz, g, kg, ml, l)
- Calcolo automatico delle percentuali
- Grafico a torta
- Salvataggio locale sul telefono
- Eliminazione singoli prodotti
- Azzeramento dello storico

## Avvio

1. Installa Flutter: https://docs.flutter.dev/get-started/install
2. Apri un terminale nella cartella del progetto.
3. Esegui:

```bash
flutter pub get
flutter run
```

## Creare APK Android

```bash
flutter build apk --release
```

L'APK verrà creato normalmente in:

`build/app/outputs/flutter-apk/app-release.apk`

## iPhone

Su macOS con Xcode installato:

```bash
flutter build ios --release
```

Per installare l'app su iPhone serve firmarla con un account Apple tramite Xcode. Per distribuirla ad altri utenti si usa normalmente TestFlight o App Store.
