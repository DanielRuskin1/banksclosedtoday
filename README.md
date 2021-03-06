# Are Banks Closed Today?

## Welcome!
"Are Banks Closed Today?" is a Rails application for checking whether banks in a given country are open.  Check it out at http://banksclosedtoday.herokuapp.com/.  If you're not able to access the site, you might need to wait a few hours (sorry - I'm on the free heroku plan).

## Getting Started
"Are Banks Closed Today?" is very simple to setup on Heroku.  Simply clone the repository, ensure that all dependencies are setup, then deploy to your Heroku application.

## Services
Various services are used for the operation of the app.  The table below shows all such services that are currently used by the app.

| Service       | Purpose                    | Required by Default    | How To Setup                                                                                                                            |
| ------------- | -------------              | ------------           | --------------                                                                                                                          |
| Heroku        | Hosting service            | No                     | Signup for heroku; set `REQUIRED_ENV_VARIABLES` from tasks/deploy.rake in `.ENV` file (not prod!); run task and complete first deploy   |
| Keen.io       | Usage metrics (e.g. usage) | Yes                    | Use Addon on Heroku (or signup and manually set env variables)                                                                          |
| NewRelic      | App metrics (e.g. speed)   | Yes                    | Use Addon on Heroku (or signup and manually set env variables)                                                                          |
| Papertrail    | App logging                | No                     | Use Addon on Heroku (or signup and manually set env variables)                                                                          |
| Rollbar       | Exception tracking         | Yes                    | Use Addon on Heroku (or signup and manually set env variables)                                                                          |
| Maxmind       | GEOIP lookups              | Yes                    | Signup on https://www.maxmind.com/en/geoip2-city and set `GEOIP_USERNAME` and `GEOIP_PASSWORD` env variables                            |
| Uptime Robot  | Uptime monitoring          | No                     | Signup on https://uptimerobot.com and configure for your site                                                                           |

## Environment Settings
In addition to the above dependencies, the app requires several additional changes to match your environment.

| Name                     | Description                             | Required by Default | Where to Set                                                                                    |
| -------------            | -------------                           | ------------        | ------------                                                                                    |
| Creator Email Address    | The email address of the site operator. | Yes                 | `CREATOR_EMAIL_ADDRESS` env variable and error pages (public/500.html, public/404.html)         |
| Rails secret token       | Necessary for cookie signing            | Yes                 | Set `RAILS_SECRET_TOKEN` env variable to random value (see config/initializers/secret_token.rb) |
| Google Site Verification | Necessary for google webmaster panel    | No                  | Signup on Google and verify site with DNS record                                                |
