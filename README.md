# space-time-maps

To run, you'll need to hook up credentials for the Google Cloud (https://console.cloud.google.com/) and Mapbox (https://www.mapbox.com/) APIs.
In Space-Time-Maps/Config, create a file named Keys.plist, and set up the following key-value pairs:

- mapboxToken: your-mapbox-API-access-token
- apiKey: your-google-maps-api-key
- iosKey: your-google-maps-sdk-key

## Mapbox
Required to calculate temporal isochrones. Free.

## Google Cloud
The API and SDK are used for different things. Calls to API cost $, however, Google provides a free $200 credit each month, and you can set up your billing settings to automatically disable API access once your budget has been hit.

I'm no longer sure why I split up the API and SDK keys, but I assume there is a reason.. :-)

### Google API
Set up and restrict your key for the following services
- Directions API
- Distance Matrix API
- Places API

### Google SDK
Set up and restrict to iOS apps.
For some reason I didn't set up further access restrictions in my own account.. but I'm quite sure it's only needed for the following SDKs
- Maps SDK
- Places SDK

With all this set up you should be good to go! :-)
