# Speed budget

Along rides are shared and on the move: a rider is walking to a stage, a
driver is in traffic. Every core action has a tap budget. A change that adds a
tap to one of these flows needs a reason in its PR.

Rules for every flow below:

- No confirm dialogs on reversible actions. Undo or retry instead.
- No spinners in front of an action the server will dedupe. Show the result
  at once (optimistic) and reconcile when the server answers.
- Inputs submit themselves when complete (the 4th PIN digit, a quick reply).
- The default is pre-filled (fare amount, top route option, last account).

## Budgets

Counted from the screen where the action starts. "Tap" includes the final
commit tap.

| Action | Who | Start | Taps | Target time | Guard |
| --- | --- | --- | --- | --- | --- |
| Book | Rider | Trip options | 1 (Request on the option card) | < 1 s to "Finding" | `mobile-rider/test/trip_options_one_tap_test.dart` |
| Join a shared ride | Rider | Trip options, passing or parked vehicle | 1 (same Request action) | < 1 s | same test |
| Board / PIN | Driver | Active trip | 1 (Enter PIN) + 4 digits; the 4th digit submits | < 3 s | `along_design/test/speed_budget_test.dart` |
| Board (rider confirms) | Rider | Meet vehicle | 1 (Boarded) | < 1 s | `live_trip_screens_test.dart` |
| New PIN | Rider | Handoff card | 1 (Get a new PIN) | < 1 s | `live_trip_wiring_test.dart` |
| Pay | Rider | Pay driver sheet | 1 (Pay, amount pre-filled) then the provider's checkout | < 2 s to checkout | `mobile-rider/test/payments_test.dart` |
| Rate | Rider | Receipt | 1 star + Done = 2 | < 2 s | `along_design/test/speed_budget_test.dart` |
| Chat: quick reply | Both | Live trip | 1 (Message) + 1 (reply) = 2 | Sheet < 100 ms, line visible on tap | `speed_budget_test.dart`, `live_trip_wiring_test.dart`, `manifest_active_trip_test.dart` |
| Chat in the car | Rider | Live trip (boarded / in transit) | 1 (Message {driver}) + 1 (reply) = 2 | same | `live_trip_wiring_test.dart` |
| Chat: typed | Both | Chat sheet | type + 1 (send arrow or keyboard Send) | line visible on tap | `speed_budget_test.dart` |

## How the chat meets its budget

- The thread is loaded when the trip goes live (`tripChatProvider` is watched
  by the trip screen from `accepted`), so the sheet opens on a full thread.
- Sends show at once as "Sending", then tick to "Delivered" and "Read".
  Failed sends retry on a timer with the same `client_ref` (the server
  dedupes); after 3 tries the line says "Not sent. Tap to retry."
- Chat is open for the live trip and 15 minutes after it ends; the 48 h
  lost-and-found thread is a separate rule (`thread = 'lost_found'`).
- Quick replies are config (`chat.quick_replies`, per role), so ops can tune
  them without an app release.

## Audit of PR #16 / #17 screens (Oct 2026)

| Screen | Finding | Change |
| --- | --- | --- |
| Rider handoff: Message | Opened the SMS app (leaves Along, shows nothing on the driver's trip screen) | Replaced with in-app chat |
| Driver active trip | No way to message the rider | Added Message with unread badge |
| Driver PIN | Already auto-submits on the 4th digit | Locked with a test |
| Receipt rating | Already 1 star + Done, tags optional | Locked with a test |
| Driver active trip panel | Overflowed on small phones once Message was added | Panel scrolls inside a 72% max height |

Not yet measured on a device: the 100 ms sheet target and the < 1 s server
round trips are design targets, checked only in widget tests and local
Postgres.
