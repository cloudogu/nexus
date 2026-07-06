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
- Projected Volume `ces-config` nach `/etc/ces/config`: `global/config.yaml` (externe ConfigMap, **nicht** vom Chart erzeugt) + `normal/config.yaml` + `sensitive/config.yaml` (chart-eigene ConfigMap/Secret). Ergebnis im Container:
  ```
  /etc/ces/config/
  ├── global/config.yaml       # externe ConfigMap
  ├── normal/config.yaml       # chart-eigene ConfigMap
  └── sensitive/config.yaml    # chart-eigenes Secret
  ```
- `dogu.json` kommt aus dem Image (`Dockerfile: COPY dogu.json /`), ein Init-Container extrahiert die Version und schreibt `/etc/ces/dogu_json/{current,<version>}` in ein gemeinsames `emptyDir`.
- doguctl löst den Deskriptor über `${HOSTNAME}` auf, nicht über den Dogu-Namen. Pod braucht `spec.hostname: <doguname>`.
- Schreibbarer `/var/ces/config` (PVC-Subpath) für `doguctl config <k> <v>`-Writes, und ein flüchtiges (ephemral) Volume `/var/ces/state` für `doguctl state ready`.

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
- `chart-patch-tpl.yaml` (ADR-0060): Image-Referenzen für `ces-mirror`

## Entwicklung

- Setup: `.env` aus `.env.template` befüllen.
- Deployen/Aktualisieren:
  ```
  make nexus-v3-install
  ```
  Baut und pusht das Image in die Dev-Registry und macht `helm upgrade --install` mit
  `--set-string nexus.image.*` + `imagePullPolicy=Always`.
- Deinstallieren (PVCs bleiben erhalten):
  ```
  make nexus-v3-uninstall
  ```