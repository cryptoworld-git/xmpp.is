VirtualHost "xmpp.cx"
http_host = "http.xmpp.cx"
modules_enabled = { "onions", "http", "register_web", "reload_modules" };
reload_modules = { "tls", "onions", "http", "register_web", "http_upload" };

	enabled = true

	allow_registration = false;
	min_seconds_between_registrations = 300
	welcome_message = "Welcome to $host, make sure you browse around the site for more details about us! https://xmpp.is/"

	c2s_require_encryption = true
	s2s_secure_auth = true

	authentication = "internal_hashed"
	storage = "internal"

	ssl = {
	   certificate = "/etc/prosody/certs/fullchain.pem";
	   key = "/etc/prosody/certs/privkey.pem";
	}

	register_web_template = "/etc/prosody/register-templates/prosody_web_registration_theme"

	--INSERT_SECRETS--

	Component "upload.xmpp.cx" "http_upload"
	http_upload_expire_after = 60 * 60 * 24 * 7
	http_upload_file_size_limit = 10000000
	http_upload_quota = 1000000000

	Component "muc.xmpp.cx" "muc"
	name = "XMPP.cx MUC"
	restrict_room_creation = "local"
        modules_enabled = { "vcard_muc", "muc_mam" };

	Component "envoy.xmpp.cx" "proxy65"
