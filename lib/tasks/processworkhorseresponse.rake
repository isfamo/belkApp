namespace :processworkhorseresponse do
  task process_work_horse_response: :environment do
    WorkHorse::ProcessWorkHorseResponse.run
  end
end

#bundle exec rake processworkhorseresponse:process_work_horse_response
