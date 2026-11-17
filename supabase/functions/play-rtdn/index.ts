import { JwksCache } from "../_shared/oidc.ts";
import { env, log, packageName, playClient, store } from "../_shared/runtime.ts";
import { handleRtdn } from "./handler.ts";

const jwks = new JwksCache();

Deno.serve((req) =>
  handleRtdn(req, {
    store: store(),
    play: playClient(),
    jwks,
    config: {
      packageName: packageName(),
      audience: env("RTDN_AUDIENCE"),
      serviceAccountEmail: env("RTDN_SERVICE_ACCOUNT_EMAIL"),
    },
    now: () => new Date(),
    log,
  })
);
