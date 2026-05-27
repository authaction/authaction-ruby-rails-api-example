%w[AUTHACTION_DOMAIN AUTHACTION_AUDIENCE].each do |key|
  raise "Missing required environment variable: #{key}" if ENV[key].blank?
end
