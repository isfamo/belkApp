## All AlphaNumeric String or Alphabetic String should be under single quotes
if ENV.fetch('RAILS_ENV') == 'production'
  Rails.application.config.IMPORT_ID = 402459
  Rails.application.config.PURGE_DAYS_DIFF = 60
  Rails.application.config.SALSIFY_BELK_HOST_SERVER = 'ftp2.salsify.com'
  Rails.application.config.SALSIFY_BELK_HOST_USERNAME = 'belk2'
  Rails.application.config.SALSIFY_BELK_HOST_PASSWORD = 'kgUTzt7zuWVZ9L3a'
  Rails.application.config.SALSIFY_WORKHORSE_FILE_LOC = '/Salsify_Workhorse/Prod'
  Rails.application.config.HEROKU_API_TOKEN = ''
  Rails.application.config.URL = ''
  Rails.application.config.HEROKU_API = ''
  Rails.application.config.WORKHORSE_HOST_SERVER = ''
  Rails.application.config.WORKHORSE_HOST_USERNAME = ''
  Rails.application.config.WORKHORSE_HOST_PASSWORD = ''
  Rails.application.config.SALSIFY_USER_EMAIL = ''
  Rails.application.config.SALSIFY_API_TOKEN = ''
  Rails.application.config.SALSIFY_ORG_SYSTEM_ID = ''
end
if ENV.fetch('RAILS_ENV') == 'development'
  Rails.application.config.IMPORT_ID = 402459
  Rails.application.config.PURGE_DAYS_DIFF = 60
  Rails.application.config.SALSIFY_BELK_HOST_SERVER = 'ftp2.salsify.com'
  Rails.application.config.SALSIFY_BELK_HOST_USERNAME = 'belk2'
  Rails.application.config.SALSIFY_BELK_HOST_PASSWORD = 'kgUTzt7zuWVZ9L3a'
  Rails.application.config.SALSIFY_WORKHORSE_FILE_LOC = '/Salsify_Workhorse/QA'
  Rails.application.config.HEROKU_API_TOKEN = '4591D7EF39D6CFE0482778AACB8A0534B99DB31317D528E310373B1BC0E16E22'
  Rails.application.config.URL = 'https://customer-belk-qa.herokuapp.com/api/workhorse/sample_requests?unsent=true'
  Rails.application.config.HEROKU_API = 'https://customer-belk-qa.herokuapp.com/api/workhorse/sample_requests'
  Rails.application.config.WORKHORSE_HOST_SERVER = 'belkuat.workhorsegroup.us'
  Rails.application.config.WORKHORSE_HOST_USERNAME = 'BLKUATUSER'
  Rails.application.config.WORKHORSE_HOST_PASSWORD = '5ada833014a4c092012ed3f8f82aa0c1'
  Rails.application.config.SALSIFY_USER_EMAIL = 'mohammed_farooqui@belk.com'
  Rails.application.config.SALSIFY_API_TOKEN = '3925569621e18e41dfedcef92341ee5f6d934e01223fe687639ea615a091e50a'
  Rails.application.config.SALSIFY_ORG_SYSTEM_ID = 's-32763a66-fe5c-4731-ab82-4ee816668005'
end
