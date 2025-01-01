require 'rails_helper'

RSpec.describe "Keywords", type: :request do
  describe "GET /index" do
    let(:elasticsearch_response) do
      {
        "aggregations" => {
          "first_agg" => {
            "buckets" => [
              {
                "key_as_string" => "2019-08-22T00:00:00.000Z",
                "key" => 1566432000000,
                "doc_count" => 5615,
                "second_agg" => {
                  "doc_count_error_upper_bound" => 0,
                  "sum_other_doc_count" => 0,
                  "buckets" => [
                    { "key" => "Online", "doc_count" => 1774 },
                    { "key" => "TV", "doc_count" => 518 },
                    { "key" => "Radio", "doc_count" => 375 },
                    { "key" => "Print", "doc_count" => 311 }
                  ]
                }
              }
            ]
          }
        }
      }
    end

    before do
      allow(ElasticsearchClient).to receive(:search).and_return(elasticsearch_response)
    end

    describe "GET /results" do
      context "when valid parameters are provided" do
        it "returns the expected response" do
          get "/results", params: {
            query: "Wilson",
            before: "2019-08-30T23:59:59",
            after: "2019-08-20T00:00:00",
            interval: "5d"
          }

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)

          expect(json_response["aggregations"]["first_agg"]["buckets"]).to be_an(Array)
          expect(json_response["aggregations"]["first_agg"]["buckets"].first["doc_count"]).to eq(5615)
          expect(json_response["aggregations"]["first_agg"]["buckets"].first["second_agg"]["buckets"]).to include(
            { "key" => "Online", "doc_count" => 1774 }.stringify_keys,
            { "key" => "TV", "doc_count" => 518 }.stringify_keys,
            { "key" => "Radio", "doc_count" => 375 }.stringify_keys,
            { "key" => "Print", "doc_count" => 311 }.stringify_keys
          )
        end
      end

      context "when query parameter is missing" do
        it "returns a bad request error" do
          get "/results"

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Keyword is required")
        end
      end

      context "when Elasticsearch raises an error" do
        before do
          allow(ElasticsearchClient).to receive(:search).and_raise(StandardError, "Something went wrong")
        end

        it "returns an internal server error" do
          get "/results", params: {
            query: "Wilson",
            before: "2023-01-02T00:00:00",
            after: "2023-01-01T00:00:00",
            interval: "1d"
          }

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Something went wrong")
        end
      end
    end
  end
end
