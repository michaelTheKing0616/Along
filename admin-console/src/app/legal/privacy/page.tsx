import { LegalChrome } from '../_components/legal-chrome';

export default function PrivacyPage() {
  return (
    <LegalChrome title="Privacy Notice (NDPA)" current="privacy">
      <section className="w03-section">
        <h2>Who we are</h2>
        <p>
          Along Mobility Ltd (&quot;Along&quot;, &quot;we&quot;, &quot;us&quot;) operates the Along
          rider and driver apps and public web pages at along.ng. We are the data controller for
          personal data described here, subject to Nigeria Data Protection Act 2023 (NDPA) and
          applicable NDPR guidance.
        </p>
      </section>

      <section className="w03-section">
        <h2>What we collect and why</h2>
        <ul>
          <li>
            <strong>Phone number</strong> — sign-in, trip updates, and (if you opt in) SMS
            receipts. Class: confidential.
          </li>
          <li>
            <strong>Name and profile</strong> — how drivers address you and account settings.
            Class: confidential.
          </li>
          <li>
            <strong>Location</strong> — plan trips, show nearby vehicles, live trip and SOS
            features. Precise samples are kept 24 hours at full resolution, then downsampled for
            up to 30 days for operations and safety. Class: confidential.
          </li>
          <li>
            <strong>Trip and fare records</strong> — matching, receipts, disputes, and commission
            accounting. Class: confidential; financial rows retained as legally required.
          </li>
          <li>
            <strong>Driver verification documents</strong> (drivers only) — identity and vehicle
            checks; stored in restricted, private storage; never shown publicly. Retained for
            verification plus 24 months unless law requires longer. Class: restricted.
          </li>
          <li>
            <strong>Device install ID</strong> — abuse detection (Sybil clustering); not IMEI.
            Class: internal.
          </li>
          <li>
            <strong>Consent records</strong> — location and notification choices with timestamps.
          </li>
        </ul>
        <p>
          We do <strong>not</strong> use third-party advertising or analytics SDKs in the mobile
          apps. Crash and performance data may be sent to Sentry with identifiers hashed or
          minimised per our security policy.
        </p>
      </section>

      <section className="w03-section">
        <h2>Payments and financial data</h2>
        <p data-testid="w03-privacy-digital-off">
          Digital payments are <strong>off by default</strong> in the Along app and in each
          city until Along enables them after legal and compliance review. When disabled, card
          and bank details are not collected in the app.
        </p>
        <p>
          When digital pay is enabled in your city, card and bank details are collected only by
          our licensed payment partner (Paystack) on hosted checkout pages. Along stores payment
          tokens and transaction references — never full card numbers.
        </p>
      </section>

      <section className="w03-section">
        <h2>How we share data</h2>
        <ul>
          <li>
            <strong>Matched parties</strong> — after you request a trip, driver and rider see the
            minimum needed to meet (name, rating, plate after accept; never pre-commit precise
            coordinates to unmatched parties).
          </li>
          <li>
            <strong>Shared trip links</strong> — if you share a live trip, viewers see first name,
            plate, mode, destination label, and a coarse live marker until the link expires (12
            hours) or you revoke it.
          </li>
          <li>
            <strong>Service providers</strong> — SMS (Termii/Twilio), payments (Paystack), hosting
            (Supabase, Vercel), and maps/routing infrastructure under contract and least privilege.
          </li>
          <li>
            <strong>Legal and safety</strong> — when required by law or to protect life and
            safety (e.g., SOS escalation to Along&apos;s safety line).
          </li>
        </ul>
        <p>
          We do not sell personal data. Aggregate, k-anonymised exports (k ≥ 10) may be produced
          for corridor planning — never individual trip trails.
        </p>
      </section>

      <section className="w03-section">
        <h2>Your NDPA rights</h2>
        <p>You may:</p>
        <ul>
          <li>
            <strong>Access and export</strong> — request a copy of your data via in-app settings
            (export job) or privacy@along.ng.
          </li>
          <li>
            <strong>Correction</strong> — update your name and preferences in the app; contact us
            for other corrections.
          </li>
          <li>
            <strong>Deletion</strong> — request account deletion; we anonymise your profile while
            keeping financial and trip records with pseudonymous IDs where law requires.
          </li>
          <li>
            <strong>Withdraw consent</strong> — turn off location or notifications in settings;
            some features will not work without location while using the service.
          </li>
          <li>
            <strong>Complain</strong> — to the Nigeria Data Protection Commission (NDPC) if we do
            not resolve your concern.
          </li>
        </ul>
      </section>

      <section className="w03-section">
        <h2>Security and retention</h2>
        <p>
          Data is protected by encryption in transit, row-level access controls, and role-based
          admin access. Incident response follows our security runbook; notifiable breaches are
          reported to NDPC within 72 hours where required.
        </p>
      </section>

      <section className="w03-section">
        <h2>Children</h2>
        <p>Along is not directed at children under 18. We do not knowingly collect their data.</p>
      </section>

      <section className="w03-section">
        <h2>Contact</h2>
        <p>
          Data Protection Officer (placeholder): privacy@along.ng · Along Mobility Ltd, Abuja,
          Nigeria.
        </p>
      </section>
    </LegalChrome>
  );
}
