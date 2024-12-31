require 'elasticsearch'

# Load the Elasticsearch configuration from the YAML file
config = YAML.safe_load(ERB.new(File.read(Rails.root.join "config/elasticsearch.yml")).result, aliases: true)[Rails.env]

ElasticsearchClient = Elasticsearch::Client.new(
  url: config['url'],
  user: config['user'],
  password: config['password'],
  log: true # Logs requests and responses for debugging
)
