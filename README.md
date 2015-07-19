== Welcome!
"Are Banks Closed Today?" is a Rails application for checking whether banks in a given country are open.  Check it out at http://are.banks.closed.today/.

== Getting Started
"Are Banks Closed Today?" is very simple to setup on Heroku.  Simply clone the repository, ensure that all dependencies are setup, then deploy to your Heroku application.

== Dependencies
In addition to the various dependencies specified in the Gemfile, some additional services are also used.  The table below shows all such services that are currently used by the app.

| Service       | Purpose                    | Required by Default    | How To Setup                                                   |
| ------------- | -------------              | ------------           | --------------                                                 |
| Keen.io       | Usage metrics (e.g. usage) | Yes                    | Use Addon on Heroku (or signup and manually set env variables) |
| NewRelic      | App metrics (e.g. speed)   | Yes                    | Use Addon on Heroku (or signup and manually set env variables) |
| Papertrail    | App logging                | No                     | Use Addon on Heroku (or signup and manually set env variables) |
| Rollbar       | Exception tracking         | Yes                    | Use Addon on Heroku (or signup and manually set env variables) |