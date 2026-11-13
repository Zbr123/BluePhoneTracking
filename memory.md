# CC Panacea 1.5 — Automation Memory / KT

Last updated: 2026-11-11  
Purpose: Durable knowledge transfer from the 1.5 APK automation chats — setup, conventions, call path, known pitfalls, client/DID context, and run history.  
Audience: Anyone picking up this work (you, another engineer, or a future agent session).

---

## 1. What this project is

- **Product**: ClearCaptions Blue phone — **1.5** APK builds (not 2.0).
- **Working automation tree**: `1.5-APK-AUTOMATION/`
- **Reference only**: `panacea-2.0-apk-automation/` (port cases / keywords from here; do not treat as the live runner).
- **Shared libs** (repo root): `Utility/`, `panacea_runtime/`, venv `panacea_env/`.
- **BluePhone delivery copy**: `C:\Users\syedz\Desktop\BluePhone` — copy **robots + keywords only**; **do not overwrite** BluePhone device/account config.
- **Git**: This 1.5 workspace often has **no git** / no commit workflow expected unless explicitly asked. BluePhone copies are file copies, not PRs, unless requested.

---

## 2. Stack & how to run

| Piece | Detail |
|-------|--------|
| Framework | Robot Framework |
| Driver | Appium **1.22.x** UiAutomator1 |
| Default Appium | `http://127.0.0.1:4735/wd/hub` |
| Device profile key | `DVT_DEVICE_109` in `ConfigFiles/deviceDetails.json` |
| App | `clrcap.CCClient` / SplashActivity |
| Python | `.\panacea_env\Scripts\python.exe` |
| Certs | Set `SSL_CERT_FILE` + `REQUESTS_CA_BUNDLE` from `certifi` before robot |
| Console encoding | `PYTHONUTF8=1`, `PYTHONIOENCODING=utf-8`; avoid `Tee-Object` (surrogateescape / broken console) |
| Console colors | Prefer `--consolecolors off` on Windows |

### Typical device run (from repo root)

```powershell
$env:SSL_CERT_FILE = (.\panacea_env\Scripts\python.exe -c "import certifi; print(certifi.where())")
$env:REQUESTS_CA_BUNDLE = $env:SSL_CERT_FILE
$env:PYTHONIOENCODING = "utf-8"
$env:PYTHONUTF8 = "1"
.\panacea_env\Scripts\python.exe -m robot -L INFO -d ".\1.5-APK-AUTOMATION\TestResults\<run_name>" `
  -v DEVICE_NAME:DVT_DEVICE_109 --consolecolors off `
  ".\1.5-APK-AUTOMATION\TestcaseSuite\UI_UX\TMCC_XXXX.robot"
```

### Dry-run

Same command with `--dryrun -L WARN`.

### Pre-flight checks

```powershell
adb devices
# expect: 192.168.137.44:5555   device
Invoke-WebRequest -Uri "http://127.0.0.1:4735/wd/hub/status" -UseBasicParsing
```

If Appium is down → start it on **4735** before running.

---

## 3. Device / account config (critical semantics)

File: `1.5-APK-AUTOMATION/ConfigFiles/deviceDetails.json`  
Profile used for almost all runs: **`DVT_DEVICE_109`**.

### Field roles (do not confuse)

| Field | Role | Current working value (as of last stable run) |
|-------|------|-----------------------------------------------|
| `udid` | ADB device | `192.168.137.44:5555` (evolved `.109` → `.230` → **`.44`**) |
| `blueDeviceId` | Blue phone hardware / VoIP targeting ID | `B34049ec9405b` |
| `calleeNumber` | **AU “My Number”** on the phone (who receives the call) | `6503196269` |
| `did_1` / `did_1_password` | **NAU softphone** that *places* the outbound/inbound test call | `6264241175` + password in json |
| `did_2` / `did_2_password` | Second DID (often same as did_1 in current setup) | same as did_1 currently |
| `userName` / `accountPassword` | QA account login | `jh-auto-s-10@cc-qa.com` / see json |
| `appium-url` | Appium hub | `http://127.0.0.1:4735/wd/hub` |
| `automationName` | Must stay **UiAutomator1** for this Appium/setup | UiAutomator1 |

**Golden rule for inbound/call cases:**  
`did_1` (NAU) **must be different** from `calleeNumber` (AU).  
If `did_1` = AU number, you get self-call / 404 / Ignore never shown.

Secrets also live in:
- `ConfigFiles/Voip_Config.yaml` (Bearer / x-auth-token for AWS make_calls)
- `ConfigFiles/testdata.yaml` (Countly / Xray / Jira tokens — framework audit noted these)

Treat those as sensitive; do not paste into BluePhone or chat casually.

---

## 4. Call / captions path (KT)

### Flow

1. Automation (or manual script) calls AWS API **`/make_calls`**.
2. API spins EC2 docker softphone → **kamailio SIP**.
3. Softphone (NAU DID + password) dials **AU** (`calleeNumber`).
4. Blue phone rings → Answer / Ignore UI.
5. Captions depend on captioner readiness + primary container lifecycle.

### Manual inbound helper

`1.5-APK-AUTOMATION/scripts/place_inbound_call.ps1`

```powershell
# Ring the phone
powershell -ExecutionPolicy Bypass -File ".\1.5-APK-AUTOMATION\scripts\place_inbound_call.ps1"
# Tear down
powershell -ExecutionPolicy Bypass -File ".\1.5-APK-AUTOMATION\scripts\place_inbound_call.ps1" -Action down
```

Defaults in the script match the working NAU→AU pair and `blueDeviceId`.

### Carrier / provisioning context (client)

- Historical path discussed: **Bandwidth**.
- Future direction discussed: **Sinch**.
- **DID provisioning is NOT automation scope** — infra / Jay / client team.
- Client contact in chats: **Taha** — ask (short, non-technical WhatsApp style) for his team to provision more QA numbers / clarify Sinch vs Bandwidth; involve Jay for AWS/SIP infra.
- Framing to client: automation can *use* DIDs once provisioned; it cannot create carrier numbers.

### Captions / wait timing decision

- Ring + answer path was made to work with correct NAU/AU split.
- Captions still flaky (captioner 60s, early “Remove Primary Container”).
- Temporary wait/captioner timing tweaks were tried then **fully REVERTED** because they caused issues when copied toward **BluePhone**.
- **Do not re-introduce wait/timing hacks** unless explicitly asked and validated against BluePhone.

---

## 5. Suite layout & inventory

Under `1.5-APK-AUTOMATION/TestcaseSuite/`:

| Folder | Purpose | Approx count (as of Nov 2026) |
|--------|---------|--------------------------------|
| `UI_UX/` | Pure UI verification | **87** robots |
| `Smoke/` | VoIP / E2E / consent / call scenarios | **18** robots |
| `DialValidation/` | Dial + Countly style | small |

Keywords: `PageObject/keywords/`  
Locators: `PageObject/locators/`  
Common entry: mega-import via **CommonKeywords** (known “god import”).

Progress pattern used in chat:
1. Port / write robots from 2.0 reference (prefer Contacts / Settings / Sounds / Home / Help / Favorites — avoid hard call cases when possible).
2. Add/adjust keywords in `Contacts.resource`, `Favorites_Steps`, `HelpVideos_Steps`, etc.
3. `--dryrun`
4. Device-run on `.44`
5. Copy robots + keyword diffs to BluePhone (not device config)

Batch size preference: **~10 cases** at a time.

---

## 6. Hard rules from the user / chat

1. **Do not break existing automation.** Prefer additive keywords/robots; avoid broad refactors.
2. Framework “safe cleanup” was done once then user asked to **revert all framework cleanup** — leave structure as-is (BLUphone/PostCall_Steps, ApiTestLibrary, etc. restored). README/scripts cleanup was undone.
3. BluePhone copy = **robots + keywords only**; leave BluePhone device/account config alone.
4. When user says “note failing why… no fix” → report only, **do not patch**.
5. Confirm before device-run / BluePhone unless user already said “run them” / “copy to BluePhone”.
6. No proactive git commits unless asked.

---

## 7. 1.5 vs 2.0 behavioral differences (learned the hard way)

| Topic | 2.0 assumption | 1.5 reality |
|-------|----------------|-------------|
| Max phone fields on New Contact | Often ≥10 / up to 12 | **Max = 6** — asserts must use ≥6 |
| Place-call / DVT crash | — | Known DVT place-call crash blocked some Smoke (e.g. TMCC_11499 3-way) on older device; **`.44` was the stable non-crashing device** |
| Favorites heart tap | Easy to hit avatar | Tap **number control** heart (`CONTACT_GRAY_HEART` / `cb_favorite`), not avatar — remove-fav cases failed until this |
| Keyword naming | Casual aliases | Robot keyword names are **case-insensitive** — aliases like “Home” vs “home”, “A” vs “a” collide; use unique names or full resource-qualified names |

---

## 8. Known failures / pitfalls (keep in mind)

### Call / inbound
- Wrong DID mapping → Ignore never appears / 404.
- Captions: “Captioner did not become ready within 60s”.
- Early remove primary container can kill captions path.

### Robot / keywords
- Ambiguous keyword example (seen in half-run):  
  `the call should be recorded as an answered call in the Call Log`  
  → qualify with `CallLog_Steps....`
- Consent WebView keywords timeout (Scenario 1) when consent UI not present / different build.
- Missing alert `btn_alert_yes`, missing `tv_name` — often setup/state/build mismatch, not always product bugs.

### Infra
- Appium down on 4735.
- Windows console encoding with Tee-Object.
- Secrets in config files (audit finding) — `.gitignore` covers TestResults but not all secret configs.
- `snap_screen.py` path historically fragile (audit noted missing/wrong path); don’t assume failure screenshots always work.

### Framework audit themes (documented, cleanup reverted)
- Secrets in repo configs
- Snap screen helper gaps
- God-import / layering / lifecycle concerns
- Decision: **document, don’t force cleanup** unless user reopens that thread

---

## 9. Important case / keyword work done in chats

### Contacts batch (examples)
Robots such as: 2994, 3014, 3044, 3047, 3055–3057, 3076, 3099, 3101 (+ earlier favorites/search/help clusters).  
Keywords extended in `Contacts.resource` for new-contact UI, max phone fields (1.5=6), cancel-with-data, etc.

### Favorites
3018–3029 style remove/add favorite — heart on **number**, not avatar.

### Smoke
- `Inbound_Captions_Smoke.robot` — receive call + captions path.
- `TMCC_11499` — 3-way call automated but historically blocked by place-call crash on bad device.
- Other Smoke IDs: 11134, 11136, 11193, 11239, 11449, 11453, 11459, Scenario_1, etc.

### Manual tooling
- `scripts/place_inbound_call.ps1` for human-driven ring/teardown without full robot.

---

## 10. Run history snapshot (important chat results)

### Half of ~106 suites (53 = first 44 UI_UX + first 9 Smoke)

| Segment | Result dir | Outcome |
|---------|------------|---------|
| Day 1 — first 36 | `TestResults/half_run_53/` | **36 PASS**, stopped mid-day |
| Day 2 — remaining 17 | `TestResults/half_run_53_rest/` | **12 PASS / 5 FAIL** |
| Combined 53 | — | **48 PASS / 5 FAIL** |

**Failures noted (no fix applied):**

| Case | Why |
|------|-----|
| Inbound Captions Smoke | Captioner not ready within 60s |
| Scenario 1 | Consent WebView/text not visible (30s) |
| TMCC 11134 | Setup: `btn_alert_yes` never appeared |
| TMCC 11136 | `tv_name` never appeared |
| TMCC 11239 | Ambiguous Call Log keyword (duplicate name) |

### Next 10 UI_UX after half-batch

| Dir | Cases | Outcome |
|-----|-------|---------|
| `TestResults/next10_uiux/` | 3056–3060, 3076, 3078–3081 | **10/10 PASS** (~46 min) |

### Remaining inventory after those runs
- Roughly **~52** suites still not in the half+next10 executed set (remaining UI_UX after 3081 + remaining Smoke).
- Full tree: 87 UI_UX + 18 Smoke (+ DialValidation).

---

## 11. Preferred working rhythm (from chat)

1. Automate ~10 UI_UX (from 2.0 gaps; Contacts/Settings-first).
2. Dry-run → device-run on `.44`.
3. Report pass/fail (+ why on fail).
4. Copy robots/keywords to BluePhone when asked.
5. Large “half of all cases” runs = note-only unless told to fix.
6. Call/captions work: verify `deviceDetails.json` NAU/AU/`blueDeviceId` **before** debugging keywords.

---

## 12. People / ownership map

| Who / what | Role |
|------------|------|
| You (local automation) | 1.5 robots, keywords, device runs, BluePhone file sync |
| Taha (client) | QA numbers / Sinch questions; keep messages short & non-technical |
| Jay / infra | DID provisioning, AWS/SIP, carrier path — **not** automation code |
| Automation scope | Consume provisioned DIDs + device config; validate app behavior |

---

## 13. Quick “if X fails, check Y”

| Symptom | Check |
|---------|--------|
| Appium session won’t start | Appium on 4735; `adb devices`; udid `.44` |
| Ignore / inbound UI never shows | `did_1` ≠ `calleeNumber`; passwords; `blueDeviceId` |
| Captions fail after answer | Captioner readiness; **don’t** casually change waits (BluePhone risk) |
| Favorites remove fails | Tapping avatar vs number heart |
| Max phone assert fails | Expect **6** on 1.5, not 10/12 |
| “Multiple keywords with name…” | RF case-insensitivity / duplicate step names — fully qualify |
| Console garbage / encoding errors | PYTHONUTF8; no Tee-Object |
| 3-way / place-call crash | Device health; known DVT issue — prefer stable `.44` |

---

## 14. Open / optional next steps (as of last chats)

- Continue remaining UI_UX/Smoke after 3081 (next batches of ~10).
- Optionally re-investigate the 5 half-run Smoke failures **only when asked to fix**.
- Client sync on Sinch / more QA DIDs (Jay) — outside code.
- BluePhone sync for any new robots/keywords not yet copied.
- Avoid reopening framework cleanup unless explicitly requested.

---

## 15. Key paths cheat sheet

```
CC_Panacea_1.5/
  panacea_env/                          # venv
  Utility/                              # Python libs
  panacea_runtime/
  panacea-2.0-apk-automation/           # REFERENCE only
  1.5-APK-AUTOMATION/                   # LIVE automation
    ConfigFiles/deviceDetails.json
    ConfigFiles/Voip_Config.yaml
    ConfigFiles/testdata.yaml
    PageObject/keywords/
    PageObject/locators/
    TestcaseSuite/UI_UX/
    TestcaseSuite/Smoke/
    TestcaseSuite/DialValidation/
    scripts/place_inbound_call.ps1
    TestResults/                        # run outputs (half_run_53*, next10_uiux, …)
  memory.md                             # THIS FILE
BluePhone (Desktop)/                    # delivery copy — robots/keywords only
```

---

## 16. One-line north star

**Automate 1.5 UI safely in small batches, run on stable device `.44` with correct NAU≠AU call config, copy only robots/keywords to BluePhone, and treat DID/Sinch provisioning as client/infra — not automation.**
