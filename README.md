# Farma
AI-driven mobile and web platform that empowers farmers with instant crop and livestock disease diagnosis, provides step-by-step 2D visual remediation guidance, enables produce buyers to evaluate food safety, facilitates direct buyer-farmer communication, and collects spatial disease outbreak telemetry for national food security monitoring.

## Flutter workspace

The current workspace targets Android, iOS and web. It includes a responsive interface and local photo records for field observations and produce drafts. It can save and reopen records on the same device once the app is running. Web startup without a connection and device-to-device sync are outside this build. The public site opens before sign-in. The current local store is for small trial datasets and separates records by Farma account on the device.

Use Flutter 3.50.1:

```sh
flutter pub get
flutter run -d chrome
flutter test
flutter build web --release
```

The Vercel project uses the build and output settings in `vercel.json`. The build script installs the pinned Flutter SDK unless one is supplied through `FARMA_FLUTTER_SDK`.

## Account access

The sign-in and signup screens use the device light or dark theme and offer nine interface languages. Country and territory calling codes come from ISO 3166 and Google libphonenumber. A phone number is collected as profile information. Email confirmation follows the Supabase Auth configuration.

Apply the versioned Supabase migration before rolling out signup to a new environment. The Auth trigger normalizes and reserves usernames in a private table. Existing accounts can sign in with their email.

## Public website

Home, About us, Profile, Projects and Services describe the current trial and planned work. The two short, captioned walkthroughs and the illustrative black-and-white photographs are original site assets. The videos are silent and playable on demand. Projects hosts the produce walkthrough and Services hosts the field walkthrough.

## Implementation status

The v3.1 product specification and the Operations & Field Console blueprint are the baseline. Commercial features retain the phase boundaries in v3.1.

| Area | Current scope |
| --- | --- |
| Field workspace | Local observation history and optional account-bound online copies, including photos. Farmers explicitly share individual online records with an approved field officer. |
| Produce showcase | Local photo drafts. Signed-in farmers can preview, publish and withdraw listings with an optional photo and photo description. Signed-in buyers can browse and search the latest 100 published listings. Listing photos load when buyers open a listing. Seller profiles show a display name, town or district, and active listings. Buyers can send one enquiry per listing and topic, and the seller can reply once in Farma. Short videos and ongoing chat are pending |
| Supabase | Email/password sign-in and signup with a unique username, country or territory, and international phone number. Storage, realtime, device sync and role policies are pending |
| Operations web console | Approved officers can open assigned observations and send a follow-up. District and partner administration, reporting, verification and campaign management are pending |
| Models and safety | Farm Assistant offers preliminary assessments when the model is configured. Validated diagnosis and professional escalation workflows are pending |
| Commercial rollout | Verification billing, advertising, payments and delivery remain pending |

## Farm Assistant

Signed-in farmers can open Farm Assistant from Overview, ask a question, or
attach a photo using the gallery or device camera. The assistant uses the
workspace language preference and can suggest questions for the next turn.
The latest answer and optional feedback can be saved on the current device.
Farmers choose whether to include their feedback as context in a later question.
No shared learning or reviewer workflow is included.

The Supabase `farm-assistant` Edge Function validates the signed-in user and
limits each account to 20 requests per hour. Set `OPENAI_API_KEY` as a
Supabase Edge Function secret, apply the Farm Assistant quota migration, and
deploy the function. The optional `FARMA_OPENAI_MODEL` setting selects a
vision-capable model that supports JSON mode. The key stays on the server.


## Online observations and field reviews

Use **Save online** on a local observation, then open **Online field records**
from Observations on any signed-in device. Use the share action to select an
approved field officer. The officer opens assigned reviews from the same screen
and can send one follow-up per request. Withdrawing a request removes the
officer’s access to the record and removes that request from both queues.

Provision approved officers in the `public.field_officers` table through
an administrator with the account UUID, display name and district. Normal
signed-in users cannot add themselves to the officer directory.
