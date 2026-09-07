import { LegalChrome } from '../_components/legal-chrome';

export default function TermsPage() {
  return (
    <LegalChrome title="Terms of Service" current="terms">
      <section className="w03-section">
        <h2>What Along is</h2>
        <p>
          Along helps riders find shared taxis, kekes, okadas, and minibuses already operating
          on the road, and helps drivers show where they are and what routes they run. Along does
          not own vehicles and is not a transport operator.
        </p>
      </section>

      <section className="w03-section">
        <h2>Who can use Along</h2>
        <p>
          You must be at least 18 years old and able to enter a binding agreement under Nigerian
          law. Drivers must complete identity and vehicle verification before matching is enabled.
        </p>
      </section>

      <section className="w03-section">
        <h2>Payments</h2>
        <p>
          <strong>Cash is the default.</strong> Most trips are paid directly between rider and
          driver in cash at the end of the trip.
        </p>
        <p data-testid="w03-digital-off-notice">
          <strong>Digital payments are off by default.</strong> Card, bank transfer, and USSD
          payments through Paystack may not appear in your app or city until Along enables them
          after legal and compliance review. When unavailable, pay your driver in cash.
        </p>
        <p>
          Along is not a wallet and does not hold customer funds. When digital pay is enabled,
          rider payments are split at checkout: the driver&apos;s share goes to their bank via a
          licensed payment partner; Along&apos;s commission is recorded separately.
        </p>
      </section>

      <section className="w03-section">
        <h2>Fares and pricing</h2>
        <p>
          Fares shown in the app come from mapped routes, crowd confirmations, or an Along Pricing
          negotiation when no standard fare exists. You agree to pay the fare you accept before
          boarding. Disputes should be reported in the app; Along may review patterns but does not
          guarantee a refund for cash trips.
        </p>
      </section>

      <section className="w03-section">
        <h2>Location and safety</h2>
        <p>
          Along uses your location to plan trips, show nearby supply, and — after a match — help
          you and your driver meet. Before you accept a driver, other users do not see your precise
          position. Use SOS only for genuine safety concerns; false alarms may affect your account.
        </p>
      </section>

      <section className="w03-section">
        <h2>Your responsibilities</h2>
        <ul>
          <li>Provide accurate phone and profile information.</li>
          <li>Treat drivers, riders, and other road users with respect.</li>
          <li>Do not use Along to harass, stalk, or circumvent platform fees through off-app deals.</li>
          <li>Do not attempt to scrape, reverse-engineer, or overload Along systems.</li>
        </ul>
      </section>

      <section className="w03-section">
        <h2>Suspension and termination</h2>
        <p>
          Along may suspend or end access for fraud, safety incidents, repeated fare disputes, or
          breach of these terms. Drivers with unsettled Along commission balances may have
          matching paused per the standing policy shown in the app.
        </p>
      </section>

      <section className="w03-section">
        <h2>Changes and governing law</h2>
        <p>
          We may update these terms. Material changes will be communicated in-app or on this page.
          These terms are governed by the laws of the Federal Republic of Nigeria. Disputes are
          subject to the courts of Abuja, FCT, unless mandatory consumer law says otherwise.
        </p>
      </section>
    </LegalChrome>
  );
}
