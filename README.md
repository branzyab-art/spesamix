# SpesaMix - Codemagic ready

Questa versione e' preparata per Codemagic.

## Android APK
1. Carica TUTTI i file di questa cartella nella root del repository GitHub `spesamix`.
2. In Codemagic apri l'app e premi **Check for configuration files**.
3. Seleziona il workflow **SpesaMix Android APK** (`android-debug`).
4. Avvia la build.
5. A build completata scarica `app-debug.apk` dagli Artifacts.

Il workflow genera automaticamente la cartella Android corretta usando la versione Flutter installata su Codemagic, poi compila l'APK.

## iPhone
E' incluso anche un workflow per il simulatore iOS. Per installare l'app su un iPhone fisico serve la firma Apple (Apple Developer / provisioning profile) e una build IPA firmata.
