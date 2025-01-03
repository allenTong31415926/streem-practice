class KeywordsController < ApplicationController
  # Handles the results request and performs Elasticsearch queries with a boolean query,
  # date range filter, and a specified time interval. Aggregates results into buckets
  # grouped by date and medium type, and returns them as JSON.
  #
  # @param [Hash] params The request parameters (all required).
  # @option params [String] :query The search query string.
  #   Example: "Wilson".
  # @option params [String] :before The end timestamp for the date range filter (ISO 8601 format).
  #   Example: "2019-08-30T23:59:59".
  # @option params [String] :after The start timestamp for the date range filter (ISO 8601 format).
  #   Example: "2019-08-20T00:00:00".
  # @option params [String] :interval The time interval for bucketing results (e.g., "1d" for 1 day).
  #   Example: "2d".
  #
  # @return [JSON] The aggregated results in the following format:
  #   @example
  #     {
  #       "aggregations": {
  #         "first_agg": {
  #           "buckets": [
  #             {
  #               "key_as_string": "2019-08-20T00:00:00.000Z",
  #               "key": 1566259200000,
  #               "doc_count": 2878,
  #               "second_agg": {
  #                 "buckets": [
  #                   { "key" => "Online", "doc_count" => 1774 },
  #                   { "key" => "TV", "doc_count" => 518 },
  #                   { "key" => "Radio", "doc_count" => 375 },
  #                   { "key" => "Print", "doc_count" => 311 }
  #                 ]
  #               }
  #             },
  #             ...
  #           ]
  #         }
  #       }
  #     }
  #
  # @raise [ActionController::BadRequest] If required parameter :query is missing.
  # @raise [StandardError] If Elasticsearch encounters an issue.
  def results
    if params[:query].blank?
      render json: { error: "Keyword is required" }, status: :bad_request
      return
    end

    # Execute the query
    response = ElasticsearchClient.search(
      index: "news",
      body: elastic_query
    )

    render json: { "aggregations": transform_response(response["aggregations"]) }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private
  def elastic_query
    {
      query: {
        bool: {
          must: [
            { query_string: { query: params[:query] } }
          ],
          filter: [
            { range: { timestamp: { gte: params[:after], lte: params[:before] } } }
          ]
        }
      },
      aggs: {
        first_agg: {
          date_histogram: {
            field: "timestamp",
            fixed_interval: (params[:interval] || "1d"),
            min_doc_count: 1
          },
          aggs: {
            second_agg: {
              terms: { field: "medium" }
            }
          }
        }
      },
      size: 0 # We're only interested in aggregation results
    }
  end

  # Transforms Elasticsearch aggregation results into a structured format for the API response.
  #
  # @param [Hash] aggregations The raw Elasticsearch aggregation response containing date_histogram
  #   and nested terms aggregations.
  #   @example Input format
  #     {
  #       "first_agg" => {
  #         "buckets" => [
  #           {
  #             "key_as_string" => "2019-08-22T00:00:00.000Z",
  #             "key" => 1566432000000,
  #             "doc_count" => 5615,
  #             "second_agg" => {
  #               "doc_count_error_upper_bound" => 0,
  #               "sum_other_doc_count" => 0,
  #               "buckets" => [
  #                 { "key" => "Online", "doc_count" => 1774 },
  #                 { "key" => "TV", "doc_count" => 518 },
  #                 { "key" => "Radio", "doc_count" => 375 },
  #                 { "key" => "Print", "doc_count" => 311 }
  #               ]
  #             }
  #           }
  #         ]
  #       }
  #     }
  #
  # @return [Hash] The transformed response structured for the API, with renamed keys and nested aggregation data.
  #   @example Output format
  #     {
  #       "first_agg": {
  #         "buckets": [
  #           {
  #             "doc_count": 5615,
  #             "key": 1566432000000,
  #             "key_as_string": "2019-08-22T00:00:00.000Z",
  #             "second_agg": {
  #               "buckets": [
  #                 { "key": "Online", "doc_count": 1774 },
  #                 { "key": "TV", "doc_count": 518 },
  #                 { "key": "Radio", "doc_count": 375 },
  #                 { "key": "Print", "doc_count": 311 }
  #               ]
  #             }
  #           }
  #         ]
  #       }
  #     }
  #
  # @note Use this method to process Elasticsearch aggregation results before returning them in the API response.
  def transform_response(aggregations)
    {
      "first_agg": {
        "buckets": aggregations["first_agg"]["buckets"].map do |bucket|
          {
            "doc_count": bucket["doc_count"],
            "key": bucket["key"],
            "key_as_string": Date.parse(bucket["key_as_string"]).to_s,
            "second_agg": {
              "buckets": bucket["second_agg"]["buckets"].map do |sub_bucket|
                {
                  "doc_count": sub_bucket["doc_count"],
                  "key": sub_bucket["key"]
                }
              end
            }
          }
        end
      }
    }
  end
end
