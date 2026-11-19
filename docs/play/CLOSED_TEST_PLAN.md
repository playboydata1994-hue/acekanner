# ACEkanner — closed test with tester swaps (12 testers × 14 days)

Owner's decision (19 Nov 2026): find testers through **tester-swap communities** (other
developers test ACEkanner, the owner tests their apps in return). The owner can also ask
12+ people they know; using both is safer, because a tester who leaves before day 14 does
not count.

**Google's rule** (personal accounts created after 13 Nov 2023): production stays locked
until a closed test has had **at least 12 testers opted in continuously for the preceding
14 days**. Testers who opt in and leave before 14 days do not count; if someone opts out
and back in, their 14 days start again. Google can also ask for more testing if tester
engagement is too low. Organization accounts do not have this rule (needs a registered
business and a D-U-N-S number; not possible now).

Aim for **20 testers**, so a few dropping out does not reset the count.

---

## A. Before the closed test (one time)

The closed test is reviewed by Google, and swap testers come from anywhere, so these must
be done first:

1. **Google sign-in for Play copies**: `PLAY_CONSOLE_SETUP.md` step 4 (App signing SHA-1 →
   Android client `ACEkanner Play builds`).
2. **Publish the sign-in consent screen**: Google Cloud → project **ACE apps** →
   **Google Auth Platform → Audience → Publish app** → Confirm. While it is in "Testing",
   only listed test users can sign in, so swap testers could not scan.
3. **Store listing** (Grow users → Store presence → Main store listing): texts from
   `STORE_LISTING.md`, icon `store/play_icon_512.png`, feature graphic
   `store/feature_graphic_1024x500.png`, at least **2 phone screenshots** (4 or more is
   better).
4. **App content** (Policy → App content): every item, answers in `APP_CONTENT.md` and
   `DATA_SAFETY.md`. Privacy policy:
   `https://playboydata1994-hue.github.io/acekanner/privacy/`.

## B. A Google Group as the tester list (one link for everyone)

1. **groups.google.com → Create group**:
   - Name `ACEkanner testers`, email `acekanner-testers@googlegroups.com` (or what is free)
   - **Privacy settings**:
     - Who can search for group: **Anyone on the web**
     - Who can join group: **Anyone can join**
     - Who can view conversations / post: **Group managers**
     - **Who can view members: Group managers** (testers' email addresses stay private)
   - Create.
2. The group's address (`https://groups.google.com/g/acekanner-testers`) is the first link
   testers open.

## C. The closed testing track

1. Play Console → ACEkanner → **Test and release → Testing → Closed testing** →
   **Create track** (or use the default "Closed testing - Alpha").
2. **Countries / regions**: select **all countries** (swap testers live everywhere; the
   public release can still be Philippines only).
3. **Testers** tab → **Google Groups** → add `acekanner-testers@googlegroups.com` →
   Save. Feedback email `espinosanoli1994@gmail.com`.
4. **Releases**: **Promote release** of `21 (0.7.3)` from Internal testing to this track
   (or Create new release → Add from library → 21) → release notes → Save.
5. **Publishing overview** → **Send changes for review**. The first review can take a few
   days. The opt-in link works only after approval.
6. Testers tab → copy the **opt-in link** ("Join on the web").

ACEkor needs its own closed test. The same group can be added to ACEkor's closed track,
so the people you know can test both apps at once.

## D. Post in tester-swap communities (after approval)

Where developers swap closed testing:
- Reddit **r/AndroidClosedTesting**, **r/TestersCommunity**, **r/AndroidAppTesters**
- Google Group **20testersforclosedtesting** ("Test for Test" posts)

Read each community's rules first. **Never offer or accept ratings or reviews in exchange
for testing**: that breaks Google Play policy and can get the app or account suspended.

Post text (fill in the two links):

```text
[Test for Test] ACEkanner – answer-sheet checker for teachers (14-day closed test)

Hi! I need testers for my first app. I'll test yours back for the full 14 days. Reply
with your group and opt-in links.

1. Join the group: <Google Group link>
2. Open the opt-in link, tap "Become a tester", then install from Google Play:
   <opt-in link>
3. Please keep it installed and stay opted in for 14 days. Opening it once in a while
   helps.

What it does: you print an answer sheet, shade circles, and the app checks it with the
camera. Everything works without an account except scanning, which needs a Google
sign-in (100 free scans).

Thanks! I've joined/installed: <list the apps you tested>
```

## E. Your side of the swap

- Join each partner's group, opt in, install their app, keep it for **14 days**, and open it
  now and then. A spare Android phone helps if you test many apps.
- Keep a list: app, developer, date joined, day 14 date.
- Do not leave anyone's test before their 14 days are up.

## F. The people you know (recommended in addition)

Message for friends, family and co-teachers (anyone 18+ with an Android phone and Gmail):

```text
Hi! Can you help me publish my teacher app ACEkanner on Google Play? Google needs 12
testers who keep it for 14 days.
1. Join: <Google Group link> (use the Gmail on your phone)
2. Open: <opt-in link> → "Become a tester" → Download from Google Play → Install
3. Keep it installed for 14 days and open it a few times. That's all, thank you!
```

## G. Counting and applying

- Play Console → Closed testing shows how many testers opted in. Check every few days.
- When at least 12 have been opted in for 14 days in a row: **Dashboard → Apply for
  production** and answer Google's questions (who tested, what feedback, what changed).
- Then `PUBLISHING_CHECKLIST.md` step 9 (production release, Philippines only).
