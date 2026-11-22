/**
 * Sends the snapshot form and reports the outcome. Kept free of DOM globals so
 * scripts/audit-funnels.mjs can run it with mocked fetch, analytics and timers.
 * A submission counts only when the endpoint returns a 2xx response.
 */
export async function submitSnapshot({ action, data, fetchImpl, track, navigate, wait = setTimeout, maxWaitMs = 1500 }) {
  let response;
  try {
    response = await fetchImpl(action, { method: 'POST', body: data, headers: { Accept: 'application/json' } });
  } catch {
    return { ok: false, message: '' };
  }
  if (!response.ok) {
    let reason = '';
    try {
      const body = await response.json();
      reason = Array.isArray(body?.errors) ? body.errors.map((e) => e?.message).filter(Boolean).join(' ') : '';
    } catch { /* Not JSON. */ }
    return { ok: false, status: response.status, message: reason.slice(0, 300) };
  }
  let done = false;
  const finish = () => { if (!done) { done = true; navigate(); } };
  track('snapshot_submitted', finish);
  wait(finish, maxWaitMs);
  return { ok: true };
}
