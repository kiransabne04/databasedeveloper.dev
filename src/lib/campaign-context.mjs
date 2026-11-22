export const campaignFields = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_content', 'utm_term'];

function cleanInternalReferrer(value) {
  try {
    const url = new URL(value);
    return ['http:', 'https:'].includes(url.protocol) ? `${url.origin}${url.pathname}` : '';
  } catch {
    return '';
  }
}

export function resolveCampaignContext(location, referrer = '', storage = null) {
  const params = new URLSearchParams(location.search || '');
  const incoming = Object.fromEntries(campaignFields.map((key) => {
    const value = (params.get(key) || '').trim().slice(0, 120);
    return [key, /^[a-z0-9][a-z0-9_-]*$/i.test(value) ? value : ''];
  }));
  const hasIncoming = Object.values(incoming).some(Boolean);
  const cleanPage = `${location.origin}${location.pathname}`;
  let context = {};
  let previousPage = '';
  let directoryReferral = '';
  try {
    const referrerUrl = new URL(referrer);
    const hostname = referrerUrl.hostname.toLowerCase().replace(/^www\./, '');
    if (referrerUrl.origin !== location.origin && (hostname === 'postgresql.org' || hostname.endsWith('.postgresql.org'))) {
      directoryReferral = 'postgresql.org';
    }
  } catch { /* Referrer attribution is optional. */ }

  try {
    context = JSON.parse(storage?.getItem('walstack-campaign-context') || '{}');
    previousPage = storage?.getItem('walstack-last-internal-page') || '';
  } catch { /* Attribution is optional; storage restrictions do not block the page. */ }

  if (!context.landing_page) context.landing_page = location.pathname;
  if (directoryReferral && !context.referral_source) {
    context.referral_source = directoryReferral;
    context.referral_landing_page = location.pathname;
  }
  if (hasIncoming) {
    const firstTaggedVisit = !context.latest_landing_page;
    for (const key of campaignFields) {
      if (firstTaggedVisit && incoming[key]) context[`first_${key}`] = incoming[key];
      if (incoming[key]) context[key] = incoming[key];
      else delete context[key];
    }
    context.latest_landing_page = location.pathname;
  }
  context.referring_page = previousPage.startsWith('/') ? previousPage : '';

  try {
    storage?.setItem('walstack-campaign-context', JSON.stringify(context));
    storage?.setItem('walstack-last-internal-page', location.pathname);
  } catch { /* Keep the in-memory values for this page view. */ }

  return { campaignContext: context, cleanPage, cleanReferrer: cleanInternalReferrer(referrer) };
}

export function successfulSubmissionEvent(response, props = {}) {
  if (!response.ok) throw new Error(String(response.status));
  return new CustomEvent('dd:track', { detail: { name: 'contact_submit', props } });
}
