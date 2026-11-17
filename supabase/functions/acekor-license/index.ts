import { ACEKOR_TOKEN_TYPE, SupabaseAcekorStore } from "../_shared/acekor.ts";
import { GoogleTokenSource, parseServiceAccount } from "../_shared/google_auth.ts";
import { signerFromSeed } from "../_shared/jws.ts";
import { GooglePlayClient, type PlayClient } from "../_shared/play.ts";
import { adminClient, env, log } from "../_shared/runtime.ts";
import { type AuthUser, handleAcekor } from "./handler.ts";

const packageName = env("ACEKOR_PLAY_PACKAGE_NAME") ?? "com.acekor.calculator";

async function getUser(jwt: string): Promise<AuthUser | null> {
  const { data, error } = await adminClient().auth.getUser(jwt);
  if (error || !data.user) return null;
  const google = data.user.identities?.find((i) => i.provider === "google");
  return {
    id: data.user.id,
    email: data.user.email ?? null,
    googleSub: (google?.identity_data?.sub as string | undefined) ?? google?.id ?? null,
  };
}

function playClient(): PlayClient | null {
  const sa = env("GOOGLE_PLAY_SERVICE_ACCOUNT");
  return sa
    ? new GooglePlayClient(
      packageName,
      new GoogleTokenSource(parseServiceAccount(sa), "https://www.googleapis.com/auth/androidpublisher"),
    )
    : null;
}

const seed = env("ENTITLEMENT_SIGNING_KEY");
if (!seed) throw new Error("ENTITLEMENT_SIGNING_KEY missing");
const signer = await signerFromSeed(seed, env("ENTITLEMENT_KEY_ID") ?? "k1", ACEKOR_TOKEN_TYPE);
const play = playClient();

Deno.serve(async (req) =>
  handleAcekor(req, {
    getUser,
    deleteAuthUser: async (id) => {
      const { error } = await adminClient().auth.admin.deleteUser(id);
      if (error) throw new Error(`deleteUser: ${error.message}`);
    },
    store: new SupabaseAcekorStore(adminClient()),
    signer,
    play,
    now: () => new Date(),
    log,
  })
);
