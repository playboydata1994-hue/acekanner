import { adminClient, entitlementSigner, log, playClient, productId, store } from "../_shared/runtime.ts";
import { type AuthUser, handleLicense } from "./handler.ts";

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

Deno.serve(async (req) =>
  handleLicense(req, {
    getUser,
    deleteAuthUser: async (id) => {
      const { error } = await adminClient().auth.admin.deleteUser(id);
      if (error) throw new Error(`deleteUser: ${error.message}`);
    },
    store: store(),
    signer: await entitlementSigner(),
    play: playClient(),
    config: { productId: productId() },
    now: () => new Date(),
    log,
  })
);
