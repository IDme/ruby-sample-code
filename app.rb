require "bundler/setup"
require "sinatra"
require "oauth2"

# Get this information by registering your app at https://developer.id.me
client_id         = "YOUR_CLIENT_ID"
client_secret     = "YOUR_CLIENT_SECRET"
redirect_uri      = "http://localhost:4567/callback"
authorization_url = "https://api.id.me/oauth/authorize"
token_url         = "https://api.id.me/oauth/token"
attributes_url    = "https://api.id.me/api/public/v3/attributes.json"

# Possible scope values: "military", "student", "responder", "teacher"
scope = "YOUR_SCOPE_VALUE"

# Enable sessions
use Rack::Session::Pool

# Instantiate OAuth 2.0 client
client = OAuth2::Client.new(client_id, client_secret, :authorize_url => authorization_url, :token_url => token_url, :scope => scope)

get "/" do
  auth_endpoint = client.auth_code.authorize_url(:redirect_uri => redirect_uri)

  <<-HTML
  <html>
    <body>
      <span id="idme-wallet-button" data-scope="#{scope}" data-client-id="#{client_id}" data-redirect="#{redirect_uri}" data-response="code"></span>
      <script src="https://s3.amazonaws.com/idme/developer/idme-buttons/assets/js/idme-wallet-button.js"></script>
    </body>
  </html>
  HTML
end

get "/callback" do
  # Exchange the code for an access token and save it in the session
  session[:oauth_token] = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)

  redirect "/profile"
end

get "/profile" do
  # Retrieve the user's attributes with the access_token we saved in the session from the "/callback" route
  token        = session[:oauth_token]
  json_payload = token.get(attributes_url).body

  content_type "text/json"
  json_payload
end
