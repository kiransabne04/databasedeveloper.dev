/**
 * Builds the track() used by BaseLayout. Events go to Plausible only when its
 * queue exists (production hostnames). The optional callback always runs, so
 * a form that waits for it never hangs when analytics is absent or blocked.
 */
export function createTracker({ getPlausible, location, campaignContext }) {
  return function track(name, extra = {}, callback) {
    const props = { source_page: location.pathname, ...campaignContext, ...extra };
    const plausible = getPlausible();
    if (plausible) plausible(name, callback ? { props, callback } : { props });
    else if (callback) callback();
  };
}

/** Props for a click on an element carrying data-track and optional data-offer. */
export function clickProps(dataset, serviceId) {
  const extra = serviceId ? { service_id: serviceId } : {};
  if (dataset.offer) extra.offer = dataset.offer;
  return extra;
}
