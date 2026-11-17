// JSON responses with stable error codes the app can act on.

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}

export function fail(status: number, error: string, message: string): Response {
  return json({ error, message }, status);
}
