require 'elasticsearch'

ElasticsearchClient = Elasticsearch::Client.new(
  url: 'https://sample.es.streem.com.au',
  user: 'candidate',
  password: 'streem',
  log: true # Logs requests and responses for debugging
)
