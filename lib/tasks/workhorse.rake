namespace :workhorse do
  task send_image_request: :environment do
    Workhorse::SendImageRequest.run
  end
end
