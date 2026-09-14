import { formatNaira, modeLabel } from '@/lib/payments/web-pay-api';
import { resolveQrDriverServer } from '@/lib/payments/resolve-server';
import type { QrResolvePayload } from '@/lib/payments/web-pay-types';
import '../pay.css';

interface PageProps {
  params: Promise<{ code: string }>;
  searchParams: Promise<{ t?: string }>;
}

function lockedAmount(resolve: QrResolvePayload): number | null {
  if (resolve.context?.locked && resolve.context.amount?.amount != null) {
    return resolve.context.amount.amount;
  }
  return null;
}

export default async function PayDriverPage({ params, searchParams }: PageProps) {
  const { code } = await params;
  const { t: token } = await searchParams;

  let resolve: QrResolvePayload | null = null;
  let loadError: string | null = null;

  try {
    resolve = await resolveQrDriverServer(code, token ?? null);
  } catch (err) {
    loadError = err instanceof Error ? err.message : 'Could not load driver';
  }

  if (loadError || !resolve) {
    return (
      <main className="w04-main w04-state" data-testid="w04-inactive">
        <h1>Code not active</h1>
        <p>{loadError ?? 'This payment code is no longer active.'}</p>
      </main>
    );
  }

  if (!resolve.driver.active) {
    return (
      <main className="w04-main w04-state" data-testid="w04-inactive">
        <h1>Code not active</h1>
        <p>This payment code is no longer active.</p>
      </main>
    );
  }

  if (!resolve.digital_enabled) {
    return (
      <main className="w04-main w04-state" data-testid="w04-not-enabled">
        <h1>Digital pay unavailable</h1>
        <p>
          Online payments are not enabled in your area yet. Please pay your driver in cash.
        </p>
      </main>
    );
  }

  if (!resolve.driver.accepts_digital) {
    const name = resolve.driver.first_name ?? 'This driver';
    return (
      <main className="w04-main w04-state" data-testid="w04-cash-only">
        <h1>{name} accepts cash only</h1>
        <p>Ask the driver for the fare and pay in cash.</p>
        {resolve.driver.plate ? (
          <p style={{ marginTop: 'var(--space-4)', color: '#fff' }}>{resolve.driver.plate}</p>
        ) : null}
      </main>
    );
  }

  const locked = lockedAmount(resolve);
  const minAmount = resolve.min_amount?.amount ?? 100;
  const chips = resolve.suggested_amounts ?? [];
  const uniqueChip = locked == null && chips.length === 1 ? chips[0].amount : null;
  const resolvedAmount = locked ?? uniqueChip;
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

  return (
    <main className="w04-main" data-testid="w04-pay">
      <p className="w04-brand">Along · Pay a driver</p>
      <h1 className="w04-plate" data-testid="w04-plate">
        {resolve.driver.plate ?? '—'}
      </h1>
      <p className="w04-driver" data-testid="w04-driver-name">
        {resolve.driver.first_name ?? 'Driver'}
      </p>
      <span className="w04-mode" data-testid="w04-mode">
        {modeLabel(resolve.driver.mode)}
      </span>

      {locked != null && resolve.context?.label ? (
        <p style={{ fontSize: '0.875rem', color: '#b8b8b8', marginBottom: 'var(--space-2)' }}>
          {resolve.context.label}
        </p>
      ) : null}

      <div className="w04-amount-display" data-testid="w04-amount">
        {formatNaira(resolvedAmount ?? 0)}
      </div>

      {!resolvedAmount && chips.length > 1 ? (
        <div className="w04-chips" data-testid="w04-chips">
          {chips.map((chip) => (
            <button
              key={chip.amount}
              type="button"
              className="w04-chip"
              data-testid={`w04-chip-${chip.amount}`}
              data-amount={chip.amount}
            >
              {formatNaira(chip.amount)}
            </button>
          ))}
        </div>
      ) : null}

      {uniqueChip != null ? (
        <button type="button" className="w04-other" data-testid="w04-other">
          Other
        </button>
      ) : null}

      {!resolvedAmount || uniqueChip != null ? (
        <div
          className="w04-keypad"
          data-testid="w04-keypad"
          hidden={uniqueChip != null}
        >
          {['1', '2', '3', '4', '5', '6', '7', '8', '9', 'back', '0'].map((key) => (
            <button
              key={key}
              type="button"
              className="w04-key"
              data-testid={key === 'back' ? 'w04-key-back' : `w04-key-${key}`}
              data-key={key}
            >
              {key === 'back' ? '⌫' : key}
            </button>
          ))}
        </div>
      ) : null}

      <div className="w04-field">
        <label htmlFor="w04-phone">SMS receipt (optional)</label>
        <input id="w04-phone" type="tel" inputMode="tel" placeholder="+234…" data-testid="w04-phone" />
      </div>

      <div className="w04-error" role="alert" data-testid="w04-pay-error" hidden />

      <div className="w04-transfer" data-testid="w04-transfer" hidden>
        <p className="w04-transfer-bank" data-testid="w04-transfer-bank"></p>
        <p className="w04-transfer-account" data-testid="w04-transfer-account"></p>
        <p className="w04-transfer-name" data-testid="w04-transfer-name"></p>
        <button type="button" className="w04-pay-btn" data-testid="w04-copy-account">
          Copy number
        </button>
        <p className="w04-transfer-wait">Waiting for your transfer</p>
      </div>

      <button
        type="button"
        className="w04-pay-btn"
        data-testid="w04-pay-btn"
        data-min={minAmount}
        data-locked={resolvedAmount != null ? String(resolvedAmount) : ''}
        data-code={code}
        data-token={token ?? ''}
        data-supabase-url={supabaseUrl}
        data-anon-key={anonKey}
      >
        Pay
      </button>

      <footer className="w04-footer">
        <a href="https://along.ng" data-testid="w04-get-along">
          Get Along for fares and routes
        </a>
      </footer>

      <script
        dangerouslySetInnerHTML={{
          __html: `
(function () {
  var digits = ${resolvedAmount != null ? String(Math.round(resolvedAmount * 100)) : "''"};
  var amountEl = document.querySelector('[data-testid="w04-amount"]');
  var payBtn = document.querySelector('[data-testid="w04-pay-btn"]');
  var errEl = document.querySelector('[data-testid="w04-pay-error"]');
  var keypad = document.querySelector('[data-testid="w04-keypad"]');
  var transferEl = document.querySelector('[data-testid="w04-transfer"]');
  var minAmount = Number(payBtn.getAttribute('data-min') || '100');
  var lockedVal = payBtn.getAttribute('data-locked');
  var isLocked = lockedVal !== '';

  function formatNaira(n) {
    return '₦' + n.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 2 });
  }

  function renderAmount() {
    var amount = digits ? Number(digits) / 100 : 0;
    amountEl.textContent = formatNaira(amount);
    payBtn.textContent = amount >= minAmount ? 'Pay ' + formatNaira(amount) : 'Pay';
    payBtn.disabled = amount < minAmount;
  }

  var otherBtn = document.querySelector('[data-testid="w04-other"]');
  if (otherBtn) {
    otherBtn.addEventListener('click', function () {
      isLocked = false;
      if (keypad) keypad.hidden = false;
      otherBtn.hidden = true;
    });
  }

  if (!isLocked || otherBtn) {
    document.querySelectorAll('[data-testid^="w04-chip-"]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var a = Number(btn.getAttribute('data-amount'));
        digits = String(Math.round(a * 100));
        document.querySelectorAll('.w04-chip').forEach(function (c) { c.classList.remove('w04-chip-selected'); });
        btn.classList.add('w04-chip-selected');
        renderAmount();
      });
    });
    document.querySelectorAll('[data-key]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var key = btn.getAttribute('data-key');
        if (key === 'back') digits = digits.slice(0, -1);
        else if (digits.length < 9) digits += key;
        document.querySelectorAll('.w04-chip').forEach(function (c) { c.classList.remove('w04-chip-selected'); });
        renderAmount();
      });
    });
  }
  renderAmount();

  payBtn.addEventListener('click', async function () {
    var amount = isLocked ? Number(payBtn.getAttribute('data-locked')) : (digits ? Number(digits) / 100 : 0);
    if (amount < minAmount) return;
    errEl.hidden = true;
    payBtn.disabled = true;
    payBtn.textContent = 'Opening checkout…';
    var phoneEl = document.getElementById('w04-phone');
    var body = {
      driver_code: payBtn.getAttribute('data-code'),
      amount: amount,
      channel: 'web',
      method_pref: 'bank_transfer',
      payer_phone: phoneEl && phoneEl.value ? phoneEl.value : undefined
    };
    var token = payBtn.getAttribute('data-token');
    if (token) body.token = token;
    try {
      var res = await fetch(payBtn.getAttribute('data-supabase-url') + '/functions/v1/payments/initiate', {
        method: 'POST',
        headers: {
          apikey: payBtn.getAttribute('data-anon-key'),
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
      });
      var json = await res.json();
      if (!res.ok) throw new Error((json.error && json.error.message) || 'Payment failed');
      var data = json.data || {};
      if (data.transfer_account && data.transfer_account.account_number) {
        var acc = data.transfer_account;
        document.querySelector('[data-testid="w04-transfer-bank"]').textContent = acc.bank_name || '';
        document.querySelector('[data-testid="w04-transfer-account"]').textContent = acc.account_number;
        document.querySelector('[data-testid="w04-transfer-name"]').textContent = acc.account_name || '';
        transferEl.hidden = false;
        payBtn.hidden = true;
        document.querySelector('[data-testid="w04-copy-account"]').addEventListener('click', function () {
          if (navigator.clipboard) navigator.clipboard.writeText(acc.account_number);
        });
        return;
      }
      if (data.authorization_url) {
        window.location.assign(data.authorization_url);
        return;
      }
      throw new Error('Checkout URL missing');
    } catch (e) {
      errEl.textContent = e.message || 'Payment failed';
      errEl.hidden = false;
      payBtn.disabled = false;
      renderAmount();
    }
  });
})();
          `,
        }}
      />
    </main>
  );
}
