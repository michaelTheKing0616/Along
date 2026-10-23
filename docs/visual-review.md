# Visual review

Three passes on the gallery. Pass 1 was read from the journey goldens (`717b292`). Passes 2 and 3 were read from the re-render in this branch, at 320 and 360, light and dark. Large text is `test/visual_scale_test.dart` (text scale 1.3 and 2.0). The 1.0 golden test still rejects wrapped short labels and overflow. Scores stay at 7 or 8.

## Pass 1 — first glance

Where am I, what is happening, what next. Top five from the journey frames, then the fix.

1. Quote, the receipt, and the PIN were a title on empty paper. The next action existed, but the page did not say which trip. Fix: each of those screens leads with "Wuse Market to Nyanya". The quote total is the heavy line. Confirm fare, Report an issue, and the PIN sentence stay put.
2. Matching put "Looking nearby" in a badge at the bottom of a busy map. Fix: a bare map, and the status card at the top with Cancel search.
3. Pickup and drop were dots. Color was the only difference. Fix: a locate icon and "Pickup" on a circle, a path icon and "Drop" on a rounded square, both on a solid chip above the anchor.
4. The rider dot was a filled mark with no approximate or stale state, and simulated positions were unlabeled. Fix: precise is a filled dot and "You". Approximate and stale are hollow and grey, with "Approx" or "Stale" and "Updated 40s ago". Debug builds add "Demo" on that position.
5. The route pulse looped, and the traveled stroke did not read as the selected part. Fix: round caps and joins, surface casing, stale remainder, ink traveled stroke. The trip camera pads for the labels and the sheet. The pulse does not run.

Re-render: quote, matching, pickup, nav, and live in `test/golden/goldens/flows/after/`.

## Pass 2 — component detail

Top five from the re-render and the scale probe, then the fix.

1. Every notice used the same info icon. Fix: denied, cancelled, and payment use distinct icons in the error role; approximate and quote-changed use warn; offline uses stale; welcome uses a check. The words stay ink.
2. The driver steps were four equal words. Fix: Arrived has a check, PIN has a verified mark and weight 600, later steps have a caret. The line under them is "Enter the rider's PIN". Verify PIN stays the button.
3. The seat count was a number next to glyphs. Fix: the caption reads "2 seats".
4. Fixed 48px and 52px rows clipped at text scale 2: ride fares, the offer route, the rider row, wallet lines, compliment chips, and the seat legend. Fix: those rows keep their 1.0 height, and above a scale of 1.05 they grow or scale down so the words stay whole. The cabin padding and cushion size are unchanged.
5. The search radar was 210px and could cover the driver chips, and it looped. Fix: 96px, rest pose, no repeat.

Re-render: the same golden set. Notices at 320×640 still shows Try again (the ink button is in the bottom band). Recovery at 320×640 shows the hollow "Approx" fix, "Updated 40s ago", and Widen radius. The driver frame shows the step icons and the keypad.

## Pass 3 — motion and accessibility

1. Search rings, the map radar, the route pulse, the GO glow, the plate sweep, the empty-state float, and the per-row stagger were looping or entering on their own. Fix: rest poses. `AlongStagger` returns the child. No second bounce.
2. Home, rides, seats, rating, wallet, offer, live, and the journey buttons overflowed at text scale 2, including 320×640. Fix: the home sheet and the seat column scroll only above scale 1.15. Buttons grow instead of ellipsizing above that scale. `test/visual_scale_test.dart` pumps every stage plus the three empty states at 320 and 360, light and dark, scale 1.3 and 2.0.
3. Reduced motion at scale 2 on a 320-wide screen still shows Confirm fare, Cancel search, Widen radius, Try again, Call 112, Report an issue, and Test haptic.
4. Press feedback under reduced motion is an opacity fade, not a scale. The sheet spring still settles inside 300ms when motion is allowed.
5. What still loops: the skeleton shimmer, and the keke refresh while its future is running. Both are loading, and both stop when content arrives. They are in the motion table in [art-direction.md](art-direction.md).

## Completion

| Criterion | Result |
| --- | --- |
| One branded product | Warm paper, one yellow, squircles, the seat word, Geist, Phosphor. |
| Focal point and next action | Named in [art-direction.md](art-direction.md) and checked on the re-rendered frames. |
| No clipping, overlap, or placeholder | 1.0 goldens pass the wrap rule. Scale 1.3 and 2.0 pass with no overflow. Demo data is labeled Demo. |
| Loading, success, empty, error | Skeleton and keke refresh, PIN matched, the three empty states, and the notice roles. |
| Reduced motion and large text | The actions listed in pass 3 stay on screen. |

Honest ceiling on the previous render: 7 to 8. The holes named there are closed in pass 4.

## Pass 4 — every defect, not the top one

Measured on the re-render at 360×800 light. A row is a defect that was visible in the pixels, and the fix.

| Screen | What was wrong | What changed |
| --- | --- | --- |
| Quote | Paper between the cancel line and Confirm fare. | The sheet is the height of the fare. The button sits 20px under the cancel line. The corridor is behind it, with no car. |
| Pickup | The pin slid across the screen. The label and the camera disagreed. The address changed during the drag. | The pin stays at the screen center. The map pans under it, lifts while the finger is down, and drops on release. The address updates on settle. The camera opens on Gate 2 at zoom 17. |
| Nav | The z12 corridor, zoomed out. | Zoom 17 on the neighborhood extract. The z16 tiles are the overzoomed z15 vector. The car sits above the sheet. No Wuse or Nyanya pins on that street. |
| PIN | A short card floated in empty paper. | The route, the instruction, and Chinedu sit at the top. The four digits follow, at 72×112. |
| Driver | 340px of paper between the digits and the keypad. The button was pinned under that hole. | Digits, keypad, and Verify PIN are one stack. |
| Receipt | The cabin floated, and the button was pinned under empty paper. | One top-aligned card. Report an issue follows the payment line. |
| Day | The timeline card stretched, leaving about 120px of empty surface above Save the day. | The board is the height of the stops. The button follows the board. |
| Earnings | The trip list stretched into empty surface above Cash out. | The list is the height of the trips. Cash out follows the list. |
| Seats | Seat perks stretched with a spacer so the note sat in a hole. | Perks are the height of the chips and the note. The hold bar follows them. |
| Matching | Search rings were a second focal on an empty map. | The rings are gone. The map shows the approximate fix under the status card. |
| Recovery | Three full-width buttons ate the map. | Widen radius stays the primary. Schedule and Try keke share the next row. |
| Notices | Seven equal banners, with Try again pinned under empty paper. | Payment failed carries Try again. The other notices are quiet rows. |
| Settings | Test haptic was pinned under empty paper. | Haptics, the reduce-motion line, and Test haptic are one card at the top. |
| Live | The sheet repeated the car's "Updated 40s ago". | The age stays on the stale car. The sheet is the ETA and Nyanya. |
| Home | "Where to?" used a plain rounded rect. | The field uses the squircle. |

Screens that were already a single focal and a single next action were left alone: onboarding, rides, search, rating, SOS, guardian, plate, wallet, online, and offer.

## Pass 5 — contact-sheet rejection

Measured on the re-render at 360×800 light after the rejection.

| Screen | What was wrong | What changed |
| --- | --- | --- |
| PIN | Four digits sat at the top of an empty page. | The driver card, car, plate, "Share this with Chinedu", and a frozen 1:48 countdown sit with the digits in the vertical center. |
| Receipt | A short card on empty paper. | A route map header, fare lines, payment, the seat, a trip timeline, the rating, then Download, Share, and Report an issue. |
| Settings | One haptics card on empty paper. | Grouped lists: account, payment, safety, accessibility, haptics, language, about. The switch and Test haptic stay live. |
| Nav | A hairline on a blank street. | Zoom 18, rotated so the white road runs up the screen. Thick casing. Maneuver banner (arrow, 180 m, Obafemi Awolowo Way). Speed and ETA bar. The car sits above that bar. |
| Offer | The cabin fill read as a grey mass. | The cushions are the seat-screen painter, with no filled shell. |
| Online | One yellow disc in the middle. | Separate district hexes, four intensity steps, a ragged dim edge, and a quiet band above GO. |
| Plate | The brackets framed the bumper, so the photo looked wide. | The hole matches the plate pixels. The photo uses BoxFit.cover at its own aspect. |
| Matching and recovery | An empty street. | A resting pulse on the pickup and three nearby drivers. |

## Pass 6 — hex grid, vector plate, offer contrast

| Screen | What was wrong | What changed |
| --- | --- | --- |
| Online | Scattered yellow splotches. | One hex grid. Ink tint steps with a hairline. Three solid yellow cells. Clear under GO. |
| Plate | The bumper photo still read as stretched. | A front-on vector plate: green band, ABUJA, ABC-123-XY. The viewfinder stays. |
| Offer | Pale grey cushions. | The seat painter at high contrast, selected yellow, inside the cabin outline. |

## Pass 7 — warm hexes, rider seats, PIN map, pickup, keypad, duotone rows

Checked at 360 and 320, light and dark.

| Screen | What was wrong | What changed |
| --- | --- | --- |
| Online | The accepted grid read grey and clinical. | Tint steps use the warn brown at low alpha. The hairline stroke is gone. Three yellow cells stay. Yellow is about 1% of the 360 frame. |
| Seats | Rider cushions were still pale grey blobs. | The cabin uses the same high-contrast painter as offer, inside the bold cabin outline. Selected is yellow. Taken and the driver are near-black. Free seats are white. Cushion size and the 20px row gap are unchanged. |
| PIN | The top 40% was empty paper. | A neighborhood map sits on top: the car is on the street, short of the pickup. The driver card, hint, 1:48, and digits follow it. |
| Pickup | Zoom 17 looked like blank land. | Building footprints, Sani Abacha Way and Wuse Market Rd, and a dashed walk that ends on the center pin. The pin still pans the map underneath. |
| Driver | Keypad digits sat on bare type. | Each key is a squircle with a hairline and a rest shadow. A press scales to 0.96 for 120ms, and the golden stays at full size. |
| Notices and settings | Rows were flat stroke icons. | Each row uses a Phosphor duotone icon. |

## Pass 8 — hex outlines and a dressed nav street

Checked at 360 and 320, light and dark. The breath rests in gallery frames.

| Screen | What was wrong | What changed |
| --- | --- | --- |
| Online | The warn tint read as muddy stains. | Small hex outlines, evenly spaced, with no fill. Stroke alpha is ink at 6, 12, or 20 percent. The top three cells are brand yellow at 85 percent, with a soft glow. The glow breathes for 2.4s and holds still when motion does not play. Yellow is under 1.1 percent of the frame. |
| Nav | Blank beige and a fat white road. | Zoom 17. Building footprints and side streets sit on the extract. The route is brand ink at 6dp on a casing. |

## Pass 9 — motion, Pass, split, rebook, departures

Checked at 360 and 320, light and dark. Motion rests in gallery frames.

| Screen | What changed |
| --- | --- |
| Rides to quote | The keke on the ride card and the quote header share one hero tag, so the vehicle flies into the fare. |
| Seats | A tap springs the cushion, depresses it, and asks for a light haptic. The rest pose and the cushion size stay. |
| Live | The ETA is a digit window. It rolls on a change and rests on 4-6 min. |
| Loading | Fare bones with the shimmer held at rest. Pass 10 rebuilds the layout. |
| Refresh | A car drives across while a refresh is in flight. Pass 10 puts the still frame on the ride list. |
| Home | Wuse to Nyanya is a regular route with one Rebook action. Where to? stays the focal. |
| Pass | A weekly Wuse to Nyanya seat and Subscribe. Pass 10 replaces the empty middle with the ticket. |
| Split | You and Ada each pay ₦600, with a share link. Pass 10 fills the card. |
| Day | Leave at suggests 06:40, 07:10, and 09:20 from corridor demand. The best time has a short accent rail. |

## Pass 10 — ticket, split, skeletons, refresh

Home, quote, live, and day stay as accepted in Pass 9. Checked again at 360 and 320, light and dark.

| Screen | What was wrong | What changed |
| --- | --- | --- |
| Pass | A short column and an empty middle. | One ticket. The top is the Wuse–Nyanya corridor. Under it: a seven-day seat calendar (Thursday is the accent seat), single fare ₦12,000 against the pass at ₦4,800, and three perks. Subscribe sits under the ticket. |
| Split | Initials, a thin bar, and an empty middle. | You and Ada use the two portraits. A ₦600 / ₦600 bar splits accent and ink. The status row reads Ada paid. The share link stays on the card. |
| Loading | Full-width grey slabs. | A map tile (land, roads, park, water, a warm sheen), then a card of round bones and text lines, then a button bone. Each bone keeps the warm shimmer. |
| Refresh | No car, only bars. | The car sits mid-road on a lane. Under it is the ride list: keke, okada, car, danfo, and bus, then Confirm keke. |

## Visual reset

Type is five sizes, 13 and up, weights 400/500/600. `AlongText.caption` and `overline` are 13. Secondary lines use ink at 72% opacity. Buttons are full-width rectangles, 56 tall, radius 16. Stadium chips are gone. Page gutters are 24. Pass days are a date and a check, not a bar.

The sheet is one surface. Home is Where to? and three saved places. The home sheet hugs that list, and the tab bar sits on the bottom safe area over the map. Seats, wallet, day, and earnings use list rows and hairlines. Earnings is the total, the week chart, and the trip list. Seats are six: two in front, four in back, inside a tapered cabin. Each cushion is a backrest bar and a rounded pan with armrest notches, one stroke weight. Selected is yellow, taken is ink, free is white with a stroke. The price sits under the cushion. Offer uses the same painter. Rating has no map band over the avatar. Tags are a two-column outline grid, radius 12. Tips are one segmented control. The wallet balance is a dark grain card with the Along wordmark, and Top up, Send, and Pass are icon and label actions. Day demand is a short meter beside High, Steady, or Quiet. Perks are one line: AC · Window · Luggage. Live ETA is plain display text. Call, Message, and Safety stay on the sheet; Share and Report sit in More.

## Pass 11 — soft map, split filled

Pass and refresh stay as accepted in Pass 10. Checked at 360 and 320, light and dark.

| Screen | What was wrong | What changed |
| --- | --- | --- |
| Loading | The map tile was a grey field with a hard white cross. | A blurred bake of the real tiles. Streets sit at low alpha, with the warm shimmer over them. The card of round bones stays. |
| Split | The lower half was empty. | A trip card (route, seat, time), a wallet row, and Remind Ada. Share link sits on the bottom safe area. |
