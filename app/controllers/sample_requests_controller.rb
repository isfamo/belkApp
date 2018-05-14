class SampleRequestsController < ApplicationController

  def create
    sample_request = request.params['sample_request']
    return unless sample_request.present?
    SampleRequest.find_or_create_by(sample_request)
  end

end
