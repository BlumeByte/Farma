# Farma
AI-driven mobile and web platform that empowers farmers with instant crop and livestock disease diagnosis, provides step-by-step 2D visual remediation guidance, enables produce buyers to evaluate food safety, facilitates direct buyer-farmer communication, and collects spatial disease outbreak telemetry for national food security monitoring.

## Flutter workspace

The current workspace targets Android, iOS and web. It includes a responsive monochrome interface and local photo records for field observations and produce drafts. It can save and reopen records on the same device once the app is running. Web startup without a connection and device-to-device sync are outside this build. The public site opens before sign-in. The current local store is for small trial datasets and separates records by Farma account on the device.

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

## Implementation status

The v3.1 product specification and the Operations & Field Console blueprint are the baseline. Commercial features retain the phase boundaries in v3.1.

| Area | Current scope |
| --- | --- |
| Field workspace | Local observation history, categories, notes and photo capture/selection |
| Produce showcase | Local photo drafts. Publishing, buyer discovery, short videos and messaging are pending |
| Supabase | Email/password sign-in and signup with a unique username, country or territory, and international phone number. Storage, realtime, device sync and role policies are pending |
| Operations web console | District and partner access, aggregate reporting, review queues, verification and campaign management are pending |
| Models and safety | The workspace records observations only. Validated diagnostic results and professional escalation are outside this build |
| Commercial rollout | Verification billing, advertising, payments and delivery remain pending |
