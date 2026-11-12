# ARUS Design System (`DESIGN.md`)

**Product**: ARUS - Mobile Business Decision-Support System & Multi-Outlet F&B POS  
**Resolved Dials**: `ENERGY 1` (quiet operational surface) / `RHYTHM 2` (clear primary-vs-secondary contrast) / `MOTION 1` (fast state feedback, 150-200ms)  
**Mode**: Slate Light Enterprise + Jade Tosca Brand Identity (WCAG AA compliant)

---

## 1. Design Read (Before Code)
ARUS serves multi-outlet F&B business owners, outlet managers, and cashiers who need fast numbers under kitchen, counter, and audit pressure. Every screen opens with a crisp light canvas (`#F8FAFC`), crisp hairline card borders (`1px #E2E8F0`), clear tabular numerals for currency and quantities, and one focal element per viewport instead of uniform floating cards or neon dark-mode leftovers.

---

## 2. Color Tokens & Verified WCAG 2.1 Contrast
Why separate `jadeTosca` from `primaryAction`? Pure `#00A896` looks vibrant as a brand accent on icons, chart bars, and active border highlights, **but fails WCAG AA** against white (`2.98:1`) and soft teal fills (`2.68:1`). Pairing it with **Teal 700 (`#0F766E`)** preserves the exact Jade Tosca brand family while guaranteeing >= 4.5:1 text and CTA legibility everywhere.

| Token | Hex | Contrast Proof | Usage Rule |
|---|---|---|---|
| `lightBackground` | `#F8FAFC` | Canvas base | App scaffold background |
| `lightCardSurface` | `#FFFFFF` | Card surface | Primary data cards, sheets, bars |
| `lightCardSurfaceElevated` | `#F1F5F9` | Subtle surface | Nested panels, inactive pills, input fills |
| `lightCardBorder` | `#E2E8F0` | 1px divider | Card outlines, list dividers (`shadowDose: 0`) |
| `textPrimaryLight` | `#0F172A` | `17.74:1` on `#FFFFFF` | Headings, hero KPIs, primary body |
| `textSecondaryLight` | `#334155` | `10.35:1` on `#FFFFFF`, `9.45:1` on `#F1F5F9` | Subheadings, secondary labels, list details |
| `textMutedLight` | `#64748B` | `4.76:1` on `#FFFFFF`, `4.55:1` on `#F8FAFC` | Captions on `#FFFFFF` / `#F8FAFC` ONLY |
| `textMutedOnElevated` | `#475569` | `6.84:1` on `#F1F5F9` | Muted labels inside `#F1F5F9` surfaces |
| `primaryAction` (`primaryToskaHover`) | `#0F766E` | `5.47:1` white-on-fill & text-on-white; `4.91:1` on `#E6F6F4` | **ALL** text links, inline accent text, BottomNav active label/icon, solid button backgrounds with white text, focus rings |
| `jadeTosca` | `#00A896` | Graphical (`3:1` UI element border/bar) | Brand mark accents, active borders, chart strokes/bars, icon tint inside soft fills when paired with `#0F766E` text |
| `successText` | `#047857` | `5.48:1` on `#FFFFFF`, `5.12:1` on `#ECFDF5` | Positive margins, valid audit chains, active status text (replaces `#10B981` / `#34D399` text) |
| `warningText` | `#B45309` | `5.02:1` on `#FFFFFF`, `4.51:1` on `#FEF3C7` | Warning badges, fallback notices, rank/stock alerts (replaces `#F59E0B` / `#D97706` text) |
| `warningTextDeep` | `#92400E` | `6.37:1` on `#FEF3C7` | Text inside warm amber `#FEF3C7` pill/banner backgrounds |
| `dangerText` | `#DC2626` | `4.83:1` on `#FFFFFF`, `4.60:1` on `#F8FAFC` | Error messages, zero-stock indicators, destructive actions (replaces `#EF4444` / `#F87171` text) |
| `dangerTextDeep` | `#B91C1C` | `5.63:1` on `#FEE2E2` | Text inside `#FEE2E2` error/out-of-stock badges |

---

## 3. Typography & Tabular Figures
- **Display / KPIs**: `Lexend` (`w700`/`w800`, tight `-0.5` letterSpacing on >= 24px numbers, `FontFeature.tabularFigures()` on currency/counts).
- **UI Body & Controls**: `Inter` (`14px` body, `12px-13px` supporting captions, normal letterSpacing except explicit monospace codes). No faux wide-tracked uppercase eyebrow slogans.
- **Scale & Hierarchy (`RHYTHM 2`)**: Hero KPI (`28-30px Lexend w800`), Section Title (`15-16px Inter w600/w700`), Row Title (`14px w600`), Supporting Caption (`12px w500`).

---

## 4. Radii, Elevation & Motion Rules
- **Radius Scale**:
  - `8px`: Chips, tags, small buttons, inputs, `ShadThemeData` controls (no pill `20px` tags everywhere)
  - `12px`: Nested panels, compact tiles, POS product tiles
  - `14px`: Primary section cards, operation tiles, dialogs
  - `16px`: Bottom sheets & Hero Omzet summary card
- **Flat Structural Elevation (`shadowDose: 0-1`)**: Cards and tiles sit flat on `1px #E2E8F0` borders without `BoxShadow`. Subtle elevation shadows (`opacity <= 0.08`) are permitted **only** on floating chrome (e.g., sticky POS cart bar, interactive map markers).
- **Zero Decorative Slop**:
  - Zero decorative gradients on buttons/cards; solid accessible fills only.
  - Zero literal emojis (`✨`, `🤖`, `🏆`, `🔥`, `🔁`, `✅`, `⚠️`, `⬅️`, `➡️`) or generic sparkle/star UI icons in chrome.
  - Zero em-dashes in UI prose; use clean colons, hyphens, or commas.
  - Brand identity screens (`Splash`, `Login`, `About`) use the real `assets/images/app_logo_mark.png` raster mark.

---

## 5. Touch Targets, Keyboard Focus & 4-State Completeness
- Interactive icons, header buttons, inline `"Lihat Semua"` links, and list actions maintain >= `44x44dp` hit area (`48dp` for primary CTAs).
- Keyboard/D-pad focus uses an explicit `2px` `#0F766E` ring (`focusColor: #1F0F766E`).
- Every async screen implements 4 crisp states via `AsyncStateView` / `EmptyStateView`: Loading indicator, Actionable Empty state (states cause + next action), Error state with live `onRetry` callback, and Validated Data state.

---

## 6. Architectural Decisions (`R-31` Rationale)
1. **Slate Light + Teal 700 (`#0F766E`) over pure `#00A896` text**: Keeps the ARUS Jade Tosca identity recognizable while raising button/link contrast from `2.98:1` to `5.47:1` across white and `#E6F6F4` surfaces.
2. **Flat `1px #E2E8F0` hairlines over layered shadows**: Reduces card haze (`ENERGY 1`) on dense mobile POS and financial screens, improving visual scan speed at `360x640`.
3. **`Lexend` hero KPIs + `Inter` dense rows + `tabularFigures`**: Prevents jitter as prices/cart counts update live and creates unmistakable `RHYTHM 2` visual hierarchy between summary totals and transaction items.
4. **Domain-faithful icons & `app_logo_mark.png`**: Replaces placeholder `'A'` boxes and generic sparkle/star icons with crisp semantic icons and actual brand assets.
