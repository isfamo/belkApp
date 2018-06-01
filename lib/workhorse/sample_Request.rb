# frozen_string_literal: true
module Workhorse
class SampleRequest
def getUnsentSampleRequest
    response = RestClient::Request.new({
    method: :get,
    url: ENV.fetch('URL'),
    headers: { :api_token => ENV.fetch('HEROKU_API_TOKEN') }
  }).execute do |response, request, result|
    case response.code
    when 400
      @sample_requests=JSON.parse(response.body)
    when 200
      @sample_requests=JSON.parse(response.body)
      #  puts(@unsent_sample_requests)
    #  [ :success, parse_json(response.to_str) ]
    else
      fail "Invalid response #{response.to_str} received."
    end
  end
  return @sample_requests
end
end
end
