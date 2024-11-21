import * as Sentry from '@sentry/browser';

const loadSentry = ['production', 'staging'].includes(document.querySelector('body').dataset.railsEnv);
if (loadSentry) {
  Sentry.init({
    dsn: 'https://511d833c4a954b6b9f54992abe16607c@o4504801902985216.ingest.sentry.io/4504802133213184',

    integrations: [Sentry.browserTracingIntegration(), Sentry.replayIntegration()],

    tracesSampleRate: 1.0,
    tracePropagationTargets: ['localhost', /^https:\/\/.*paradisec.org.au\.io\//],

    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,
  });
}
