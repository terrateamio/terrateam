// Import required modules using ES module syntax
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Required for compatibility with __dirname in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Check if we are in production
if (process.env.NODE_ENV !== 'production') {
  console.log('Skipping ph-init.js generation because NODE_ENV is not set to production.');
  process.exit(0); // Exit without error
}

// Retrieve the API key from the environment
const POSTHOG_API_KEY = process.env.POSTHOG_API_KEY;

// Check if the environment variable is set
if (!POSTHOG_API_KEY) {
  console.error('Error: POSTHOG_API_KEY is not set');
  process.exit(1); // Exit with error
}

// Define the contents of ph-init.js with the API key
const content = `
!function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.async=!0,p.src=s.api_host.replace(".i.posthog.com","-assets.i.posthog.com")+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="init push capture register register_once register_for_session unregister unregister_for_session getFeatureFlag getFeatureFlagPayload isFeatureEnabled reloadFeatureFlags updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures on onFeatureFlags onSessionId getSurveys getActiveMatchingSurveys renderSurvey canRenderSurvey getNextSurveyStep identify setPersonProperties group resetGroups setPersonPropertiesForFlags resetGroupPropertiesForFlags setGroupPropertiesForFlags reset get_distinct_id getGroups get_session_id get_session_replay_url alias set_config startSessionRecording stopSessionRecording sessionRecordingStarted loadToolbar get_property getSessionProperty createPersonProfile opt_in_capturing opt_out_capturing has_opted_in_capturing clear_opt_in_out_capturing debug".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);

posthog.init('${POSTHOG_API_KEY}', {
    api_host: 'https://eu.i.posthog.com',
});
`;

// Write the file to the public directory
fs.writeFileSync(path.join(__dirname, 'public', 'ph-init.js'), content);
console.log('ph-init.js generated with POSTHOG_API_KEY');
