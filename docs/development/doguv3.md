# Nexus - Dogu v3


## Erstllung des v3 Dogus

- **Startup-Skripte bleiben unverändert.** `doguctl` funktioniert auch in DoguV3 — es liest seine Config nur
  aus gemounteten Dateien.
- Ein Container pro fachlicher Rolle (Hauptanwendung, ggf. Reverse-Proxy im selben Container, Sidecars für
  zusätzliche APIs, eigene DB als StatefulSet).

### 1. Chart-Gerüst

- `Chart.yaml`: Pflichtfelder `name`, `version`, `appVersion`, `description`,
  `annotations.dogu.cloudogu.com/api-version: v3`.
- `.helmignore`
- `values.yaml`: ein Block je Container (`<dogu>.image`, `<dogu>.resourceRequests`, ...). Querschnittswerte (`global`, `networkPolicies`) bleiben top-level.

### 2. doguctl-Config-Mount (Component-Mode)

- Env `ECOSYSTEM_MULTINODE=true` auf jedem Container/Init-Container setzen, der `doguctl` aufruft.
  - Volume in `${GLOBAL_CONFIG_DIR}` hast `config.yaml` (externe ConfigMap, **nicht** vom Chart erzeugt)
  - Volume in `${DOGU_CONFIG_DIR}` hast `config.yaml` (chart-eigene ConfigMap)
  - Volume in `${SENSITIVE_CONFIG_DIR}` hast `config.yaml` (chart-eigene Secret)
  - Volume in `${LOCAL_CONFIG_DIR}` hast `local.yaml` (beschreibbare lokale Konfiguration)
  - Ergebnis im Container:
    ```
    ├── ${GLOBAL_CONFIG_DIR}/config.yaml       # externe ConfigMap
    ├── ${DOGU_CONFIG_DIR}/config.yaml         # chart-eigene ConfigMap
    └── ${SENSITIVE_CONFIG_DIR}/config.yaml    # chart-eigenes Secret
    └── ${LOCAL_CONFIG_DIR}/local.yaml         # beschreibbare lokale Konfiguratio
    ```
- `dogu.json` kommt aus dem Image (`Dockerfile: COPY dogu.json /`), ein Init-Container extrahiert die Version und schreibt `${DOGU_REGISTRY_DIR}/{current,<version>}` in ein gemeinsames `emptyDir`.
- doguctl löst den Deskriptor über `${HOSTNAME}` auf, nicht über den Dogu-Namen. Pod braucht `spec.hostname: <doguname>`.
- Schreibbarer `$LOCAL_CONFIG_DIR` (PVC-Subpath) für `doguctl config <k> <v>`-Writes, und ein flüchtiges (ephemeral) Volume `/var/ces/state` für `doguctl state ready`.

### 3. Non-root-Härtung (optional)

- Root-Init-Container holt das CES-Zertifikat und macht `chown -R` auf Daten- und Config-Verzeichnisse.
- Hauptcontainer läuft als `uid 1000`, ruft `startup.sh` direkt per `args` auf (kein `su`, kein
  `pre-startup.sh`), `HOME` explizit setzen.

### 4. Self-contained Abhängigkeiten

- Eigenes StatefulSet statt externem Dogu.
- Secret-Passwort per `lookup`-Pattern gegen Rotation bei `helm upgrade` schützen (sonst neues Passwort bei jedem Upgrade).
- Falls Startup-Skripte einen Hostnamen hart verdrahtet haben (z. B. `postgresql:5432`): per Env überschreibbar machen, Default für v2 beibehalten.

### 5. Erreichbarkeit

- Im Cluster: Service (`service.yaml`)
- Nach Außen: Exposition-CR (`exposition.yaml`)
- Warp-Menü: WarpMenuEntry-CR (`warp.yaml`)
- CAS-SSO: AuthRegistration-CR (`auth-registration.yaml`)
- Network-Polcies (`network-policies.yaml`): Namespace hat ein `deny-all-ingress`; explizite Allow-Policies für benötigte Zugriffe einrichten.

### 6. Service-Accounts als Producer

- Generischer HTTP-Sidecar ([`service-account-producer-sidecar`](https://github.com/cloudogu/service-account-producer-sidecar)) verwenden. 
  Führt konfigurierte Hook-Skripte aus, kein Dogu-Wissen im Sidecar selbst.
- Die Hooks sollten am besten durch Wrapper-Skripte gekapselt werden, die die übergebenen Parameter auswerten und an die existierens Skripte weiterleiten. 
  So bleiben die eigentlichen Skripte unverändert.

### 7. Konfigurierbarkeit & Validierung (Release-Politur)

- `dogu-values-metadata.yaml` (ADR-0058): Mapping für die Dogu-CR (`mappedValues`, z. B. Log-Level).
- `values.schema.json` (ADR-0058): JSON-Schema für `values.yaml` 
- `mirror-patch-tpl.yaml` (ADR-0060): Image-Referenzen für `ces-mirror`

## Entwicklung

Entwicklung und Release laufen über `build/make/dogu-v3.mk` aus den makefiles, das [cldk](https://github.com/cloudogu/cldk) aufruft.
Details zu Variablen und Ablauf stehen in `docs/operations/dogu-v3-de.md` im makefiles-Repo.

- Setup: `.env` aus `.env.template` befüllen. `STAGE=development` ist nötig, sonst bricht `dogu-apply` ab.
  Ziel-Cluster wie bei v2 über `RUNTIME_ENV`, `KUBE_CONTEXT_NAME` und `NAMESPACE`; `CLDK_DEV_*`-Variablen müssen nicht gesetzt werden, sie werden daraus abgeleitet.
- Deployen/Aktualisieren:
  ```
  make dogu-apply
  ```
  Lädt cldk nach `.bin/cldk` (falls nötig), baut das Image, pusht Image und Chart unter einer neuen Dev-Version
  (`<Chart-Version>-dev.<Zeitstempel>`) in die Dev-Registry und installiert bzw. aktualisiert das Dogu im Cluster.
- Deinstallieren (PVCs bleiben erhalten):
  ```
  kubectl -n <namespace> delete dogu nexus
  ```

## Release

`make dogu-release` released Nexus wegen der `cldk.yaml` als v2- und v3-Dogu zugleich (Doppel-Release):

- „Release the v2 dogu as well?“ mit `y` beantworten, dann die neue v2-Dogu-Version und die neue Chart-Version angeben.
  Der Release setzt `version` und `appVersion` im `k8s/helm/Chart.yaml` und den Image-Tag in der `cldk.yaml`.
- Mit `n` wird nur das Chart released (z. B. bei einer reinen Chart-Änderung), Branch `release/chart/v<Chart-Version>`.

Image und Chart veröffentlicht anschließend die Jenkins-Pipeline.
