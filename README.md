# Farma
AI-driven mobile and web platform that empowers farmers with instant crop and livestock disease diagnosis, provides step-by-step 2D visual remediation guidance, enables produce buyers to evaluate food safety, facilitates direct buyer-farmer communication, and collects spatial disease outbreak telemetry for national food security monitoring.

## Flutter workspace

The current workspace targets Android, iOS and web. It includes a responsive monochrome interface and local photo records for field observations and produce drafts. It can save and reopen records on the same device once the app is running. Web startup without a connection and device-to-device sync are outside this build. The current local store is for small trial datasets.

Use Flutter 3.50.1:

```sh
flutter pub get
flutter run -d chrome
flutter test
flutter build web --release
```

The Vercel project uses the build and output settings in `vercel.json`. The build script installs the pinned Flutter SDK unless one is supplied through `FARMA_FLUTTER_SDK`.

## Implementation status

The v3.1 product specification and the Operations & Field Console blueprint are the baseline. Commercial features retain the phase boundaries in v3.1.

| Area | Current scope |
| --- | --- |
| Field workspace | Local observation history, categories, notes and photo capture/selection |
| Produce showcase | Local photo drafts. Publishing, buyer discovery, short videos and messaging are pending |
| Supabase | Authentication, storage, realtime, device sync and role policies are pending access to the Farma project |
| Operations web console | District and partner access, aggregate reporting, review queues, verification and campaign management are pending |
| Models and safety | The workspace records observations only. Validated diagnostic results and professional escalation are outside this build |
| Commercial rollout | Verification billing, advertising, payments and delivery remain pending |
