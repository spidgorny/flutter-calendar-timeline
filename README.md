# Flutter Calendar Timeline

Flutter client that mirrors the `calendar-timeline` website flow:

1. Sign in with Google.
2. Use the Google access token as `Authorization: Bearer <token>`.
3. Fetch all-day multi-day events from:
   `GET /api/mobile/all-day-events?calendarId=<id>`.
4. Render them in a horizontal month/day timeline with event bars.

## Configuration

Set backend and calendar via `--dart-define`:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=CALENDAR_ID=primary
```

## Google sign-in setup

Configure Google Sign-In for your Flutter platform (Android/iOS) with the same
Google OAuth project used by the website, and keep calendar read scope enabled:

- `https://www.googleapis.com/auth/calendar.readonly`

## Notes

- The app expects the website API to be reachable and authenticated with bearer token.
- Timeline window matches the website behavior: today through next 6 months.
