MANDRILL_API_KEY_TEST ||= "tXVwuFz7NJc5Xm__4mD_4A" #This is the test key. It doesn't actually send emails.
MANDRILL_API_KEY ||= "Ks23qw8MFFmLr54SycU8og" #This is the Developer key. IT SENDS EMAIL!
DEFAULT_FROM_EMAIL ||= "\"Peerstudio Accounts\" <accounts@peerstudio.org>"
DEFAULT_TO_EMAIL ||= "test_user@your.domain"
ACTION_MAILER_DELIVERY_METHOD ||= :smtp
ACTION_MAILER_SMTP_SETTINGS ||= {
  :address              => "smtp.mandrillapp.com",
  :port                 => 587,
  :domain               => 'learningapi.stanford.edu',
  :user_name            => 'chinmay@cs.stanford.edu',
  :password             => MANDRILL_API_KEY,
  :authentication       => 'login',
  :enable_starttls_auto => true  }

ACTION_MAILER_SMTP_SETTINGS_DEVELOPMENT ||= {
  :address              => "smtp.mandrillapp.com",
  :port                 => 587,
  :domain               => 'learningapi.stanford.edu',
  :user_name            => 'chinmay@cs.stanford.edu',
  :password             => MANDRILL_API_KEY_TEST,
  :authentication       => 'login',
  :enable_starttls_auto => true  }

puts "constants loaded"