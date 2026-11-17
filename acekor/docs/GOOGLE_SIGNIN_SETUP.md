# Google sign-in setup (ACEkor Grading Sheet and ACEkanner)

The free trial and the subscriptions use a one-time Google sign-in. One Google Cloud project and
one Supabase project serve both apps. Doing these steps once turns on sign-in for ACEkanner too.

Use a computer. Takes about 20 minutes.

**Never send in chat:** the client **secret**, passwords, or any downloaded JSON file.
**Send me only:** the **Web client ID** (it ends in `.apps.googleusercontent.com`; it is public).

## A. Google Cloud project

1. Open **console.cloud.google.com** and sign in with your developer Google account.
2. In the project picker (top left), choose the **ACEkanner** project if it exists; otherwise click
   **New project**, name it `ACE apps`, and create it. Make sure it is selected at the top.

## B. Consent screen (what instructors see when they sign in)

1. Go to **APIs & Services → OAuth consent screen** (it may be called **Google Auth Platform**) and
   click **Get started**.
2. Fill in:
   - **App name:** `ACE apps by NYE94` (shown for both apps).
   - **User support email:** your email.
   - **Audience:** **External**.
   - **Contact email:** your email.
   Then click **Create**.
3. Go to **Audience → Test users → Add users** and add the Gmail accounts you will test with.
   While the app is in "Testing", only these accounts can sign in. You can **Publish app** later.

## C. Web client (used by the server)

1. Go to **Clients → Create client → Web application**.
2. Name it `Supabase (ACE apps)`.
3. Under **Authorized redirect URIs**, add:
   `https://ajmdnsdhrpktkvkxnmuo.supabase.co/auth/v1/callback`
4. Click **Create**. A box shows the **Client ID** and the **Client secret**.
   - **Send me the Client ID.**
   - Keep the box open for step D (the secret goes only into Supabase).

## D. Supabase

1. Go to **supabase.com → project `acekanner` → Authentication → Sign In / Providers → Google**.
2. Turn **Sign in with Google** on.
3. **Client IDs:** paste the Web Client ID.
4. **Client Secret:** paste the Web client secret.
5. Leave **Skip nonce checks** off, then click **Save**.

## E. Android clients (one per app and per signing key)

Google checks that sign-in comes from the real app. For each signing key below, go to
**Clients → Create client → Android**, enter the package name and the key's SHA-1, and click **Create**.

| Client name | Package | SHA-1 |
|---|---|---|
| ACEkor upload key | `com.acekor.calculator` | `55:7E:4A:02:F4:0A:50:C3:24:20:09:1A:88:39:E0:52:7F:80:BA:4F` |
| ACEkor Play builds | `com.acekor.calculator` | Play Console → ACEkor → **Test and release → App integrity → App signing key certificate → SHA-1** (available after the first upload) |
| ACEkanner upload key | `com.acekanner.app` | `65:75:4A:42:B5:46:71:98:9B:BB:30:2E:D7:52:B6:32:22:4D:3E:01` |
| ACEkanner Play builds | `com.acekanner.app` | From ACEkanner's App signing page |

## What happens next

Once you send the Web client ID, I put it into both apps' build settings and build signed app
bundles. ACEkor's trial then starts from the real server, with no reset by reinstalling.
