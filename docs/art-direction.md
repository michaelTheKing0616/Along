# Art direction

Along should feel calm and specific: an Abuja seat, a real landmark, one next step. Riders get a quiet page that names the place and the fare. Drivers get one instruction and almost no chrome while the vehicle is moving. It is not a black-on-white clone, not a green bid app, and not a pink one. One yellow (`#F7D117`) is the accent, and it stays under 10% of any screen.

Build to this note. The trip lifecycle is in [flows.md](flows.md). Each visual pass is logged in [visual-review.md](visual-review.md).

## Signature

| Piece | Rule |
| --- | --- |
| Color | Warm paper and ink. Light background `#F6F4F1`, surface `#FBF9F6`, ink `#141210`. Dark background `#100F0D`, surface `#26231F`, ink `#F3EEE8`. Accent `#F7D117` with ink `#141210` on it. |
| Shape | Squircles at smoothing 0.6 (`AlongCraft`). Pills (radius 999) and circular controls stay round. |
| Seat | The seat glyph is the product mark. Counts read as glyphs plus the word "seats", not a bare number. |
| Map | Baked muted tiles. No color matrix. Labels sit on solid surface chips. The route has a surface casing, a grey remainder, and an ink traveled stroke. |
| Type | Geist, two weights (600 and 400), tabular figures, hanging naira. Inter is only the naira fallback. |
| Icons | Phosphor Duotone, from the font. A state is an icon plus words. Color never carries the state alone. |

## Semantic roles

`AlongPalette.roles` (`AlongRoles`) is the only place map and status colors are chosen.

| Role | Use | Light / dark |
| --- | --- | --- |
| `route` | Traveled / selected stroke | Ink |
| `routeCasing` | Stroke outline | Surface |
| `pickup` | Pickup anchor | Accent, plus a locate icon and the word Pickup |
| `dropoff` | Drop anchor | Ink, plus a path icon and the word Drop. The anchor is a rounded square, not a circle. |
| `riderDot` | Precise "You" | Ink fill, word You |
| `driverMarker` | Driver disc | Ink |
| `stale` | Old or approximate fix | Muted. Hollow ring, greyed disc, and the words "Approx" or "Stale" plus "Updated 40s ago". |
| `success` | Matched, welcome | Palette success, plus a check icon and words |
| `warn` | Approximate fix, quote change | `#7A4E16` / `#E7C98A`, plus an icon and words |
| `error` | Denied, cancelled, payment failed, wrong PIN | Palette danger, plus an icon and words |
| `mapLand`, `mapWater`, `mapPark`, `mapRoad` | Tile-matching paint only | Unchanged from the baked tiles |

Map light and map dark are the two baked extracts (`assets/map/tiles/light` and `dark`). They are not a recolor of each other.

## One focal point, and how dense the page is

Every screen has one thing to look at and one next action. Everything else is quieter. Density is the number of competing clusters, not a pixel count.

| Screen | Ride phase | Focal element | Next action | Density |
| --- | --- | --- | --- | --- |
| Home | idle | "Where to?" | Open search | Sheet over a quiet map |
| Pickup | pickup | Hollow pin and the detected place | Pick a landmark | Map, one card, one chip list |
| Quote | quote | The total | Confirm fare | One list, one button |
| Matching | matching | "Looking nearby" | Cancel search | Bare map, one card |
| Recovery | no driver | "No driver yet" | Widen radius | Bare map, three actions, one primary |
| Rides | quote | The selected ride | Confirm keke | One recommended row, a short list |
| Seats | quote | The selected cushion | Hold this seat | Cabin, then one bar |
| Offer | assigned | The fare | Accept | One card over the route |
| PIN | arrived | The four digits | Share them with Chinedu | Driver card, car, plate, countdown, digits, centered |
| Driver | arrived | The PIN step | Verify PIN | Steps, digits, keypad |
| Live | in progress | The ETA range | Call, or Safety | Map, one sheet |
| Nav | nav | The next maneuver | Keep driving | Banner, lane route, speed and ETA |
| Receipt | receipt | The total and the seat | Report an issue | Map, fare, payment, seat, timeline, rating |
| Notices | closed and the failures | The banner that applies | Try again | The gallery shows the catalog. Production shows one banner and one action. |
| Settings | — | The haptics switch | Test haptic | Grouped account, payment, safety, access, haptics, language, about |
| SOS | any | Call 112 | Hold to call, or share with contacts | One hold. No promise of a staffed desk. |
| Empty | — | The heading | The single action on the empty state | Icon, heading, body, one button |

## Map

Markers are anchored and purposeful. A label sits above its dot, on a solid surface chip, and does not cover another label. Pickup is a circle. Drop is a rounded square. Both carry an icon and a word.

Route strokes use round caps and round joins. Casing is `routeCasing`. The remainder is `stale`. The traveled portion is `route` and is the selected state. There is no pulsing overlay.

The trip camera frames pickup and drop together. Padding clears the top labels and the sheet: 28 on the sides, 72 on top, and `sheetInset` plus 36 on the bottom. The corridor stays inside the z12 tiles (trip max zoom 12).

Nav does not fit that corridor. It locks zoom 18 on the white east-west road in the z16 extract, rotated so that street runs up the screen. The route casing is the lane stroke. A maneuver banner (arrow, street, distance) sits on top. Speed and the ETA share the bottom bar. The car is shifted down the screen so it clears that bar. Wuse and Nyanya pins are not drawn on that local street.

The pickup pin is fixed at the screen center. A drag pans the map under it. The pin lifts while the finger is down and drops on release. The address updates when the drag settles, and snaps to an entrance within 120 meters. The camera opens on Gate 2 at zoom 17 so the pin sits on the extract.

The quote sheet is only as tall as the fare. Confirm fare sits on the cancel line. The corridor is behind that sheet, and no car is drawn until the trip is moving.

An approximate or stale fix is hollow and grey, with the words "Approx" or "Stale" and "Updated Xs ago". A precise fix is a filled dot and the word "You". Simulated positions say "Demo" in debug builds. A screen that already shows a Demo mark does not add a second one on the map.

Pickup uses a bare map so decorative pins do not cover the place. The pickup pin itself is the hollow anchor. Matching and recovery keep the status in the card and add a resting pulse on the pickup plus nearby driver chips, so the street is not empty. The approximate fix stays on that pickup. Online demand is one hex grid over the visible city. Steps are flat ink tints with a hairline edge. Two or three cells are solid brand yellow. The band under the GO button stays clear.

## Motion

Named lengths live on `AlongDurations`. Curves live on `AlongCurves`. Springs live on `AlongSprings`. Nothing else invents a duration. Reduced motion wins over every row below: fades and opacity replace movement, and `AlongMotionPolicy.play` is false. Gallery frames are the rest pose.

| Animation | Token | What changes | What it tells the rider | Interruptible |
| --- | --- | --- | --- | --- |
| Press | `press` 120ms. Reduced motion uses opacity 0.72 instead of scale 0.96. | The control acknowledges the finger. | The press landed. | Yes. Release or cancel returns it. |
| Fade | `fade` 180ms, `AlongCurves.fade` (easeOut) | Opacity of a status that cannot move. | Something settled without a slide. | Yes. |
| Sheet | `AlongSprings.sheet` (mass 0.7, stiffness 520, damping 32). Visually at rest inside 300ms. `sheet` 280ms is the paired length. | The sheet position. | Where the page now sits. | Yes. A drag takes over. |
| Pin | `sheet` 280ms, `AlongCurves.settle`. Duration zero when motion does not play, so the rest pose is the dropped pin. | The pin lifts while the finger drags and drops on release. The map pans under it. The address changes on settle. | The pickup is placed. A nearby entrance snaps. | Yes. Release settles it. |
| Route | `routeDraw` 900ms, `AlongCurves.settle` (easeOutCubic), `AlongSprings.route` | The traveled stroke. | How far along the trip is. | Yes. A new progress replaces it. |
| Refresh | `refresh` 480ms | The keke rocks, only while the refresh future is running. | The list is loading. | Yes. It stops when the future ends. |
| Hold | `hold` 1400ms for a one-shot status. The SOS hold control is 600ms. | A bar fills while the finger stays down. | Keep holding to call 112. Release cancels. | Yes. |
| Scan | `scan` 1800ms | Was a sweep. It now holds a rest pose. | Nothing. The words carry the status. | — |
| Skeleton | 1200ms shimmer | A sheen crosses the block. | Content is on its way. | Yes. Real content replaces it. |

Do not animate every element on entry. `AlongStagger` returns the child. Do not loop decoration: search rings, the map radar, the route pulse, the GO glow, the plate sweep, and the empty-state float stay on a rest pose. Do not bounce a control twice. The skeleton shimmer and the in-flight refresh are progress, not decoration.

## Native, and brand

Native, leave it alone: the system back gesture, the text scaler, the reduce-motion switch, `tel:112`, and the platform haptic channel.

Brand, and build it here: color, squircle radius, the seat motif, Geist, Phosphor, map markers and route casing, the haptic toggle's meaning, and which motion is allowed to play.

## Critique loop

On every visual pass:

1. Render the gallery goldens, including failure and empty states (recovery, notices, the three empty states).
2. Check 320 and 360, light and dark, and text scale 1.3 and 2.0. The 1.0 golden wrap rule stays on the golden test. Large text is `test/visual_scale_test.dart`: wrapping is allowed, overflow and a clipped action are not.
3. First glance, per screen: where am I, what is happening, what do I do next.
4. Write the top five problems, fix them, and render again.
5. Pass 2 is component detail. Pass 3 is motion and accessibility.
6. Log each pass's top five in [visual-review.md](visual-review.md).

A pass is done when all of these are true: one branded product, a clear focal point and next action on each screen, no clipping, overlap, or placeholder, designed loading, success, empty, and error states, and the essential actions still readable with reduced motion and large text.
