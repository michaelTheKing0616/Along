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
