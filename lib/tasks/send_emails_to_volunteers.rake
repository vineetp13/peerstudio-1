namespace :assignment do
	task :remind_to_submit => :environment do
		logger = Rails.logger
		assignments = Assignment.active.where('due_at < ?', Time.now+2.days).where(course_id: 4)
		logger.info "Sending emails to remind people to submit to Coursera"
		if !assignments.nil?
			assignments.each do |assignment|
				answers = assignment.answers.select(:user_id).distinct
				answers.each do |answer|
					logger.info "Sending email to remind #{answer.user_id}"
					ReviewMailer.delay.submit_on_coursera(answer.user_id, assignment.id)
				end
			end
		end
	end

	task :send_emails_to_volunteers => :environment do
		logger = Rails.logger
		assignments = Assignment.active
		logger.info "Sending emails to people who need it + volunteers"

		#Different database servers on development and production
		if Rails.env.development?
			random_function = "RANDOM()" #postgresql
		elsif Rails.env.production?
			random_function = "RAND()" #mysql
		else
			logger.info "Choosing created_at because we can't figure out our environment"
			random_function = "created_at"
		end

		if !assignments.nil?
			assignments.each do |assign|
				thirty_min_ans = assign.answers.where(submitted: true, total_evaluations: 0, review_completed: false).where("submitted_at <= ?", 30.minutes.ago)
				if thirty_min_ans.count > 0
					logger.info "Found unreviewed answers: #{thirty_min_ans.count}"
					#here, we find people who still need to give reviews
					have_to_review_still = TriggerAction.where(assignment_id:assign.id,trigger: "review_required").where(["count > ? and (last_email_time IS NULL or last_email_time < ?)", 0, 12.hours.ago]).order(random_function).limit(4)
					review_requests = thirty_min_ans.where('review_request is not NULL').map {|a| a.review_request}
					if have_to_review_still.empty? #nil didn't work, so used empty
						#if no one needs to give reviews, we move onto volunteers, aka people who don't need to give any more reviews
						volunteers = TriggerAction.where(assignment_id:assign.id,trigger: "email_count").where(["count > ? and (last_email_time IS NULL or last_email_time < ?)", 0, 24.hours.ago]).order(random_function).limit(4)
						volunteers.each do |vol| #send email, set last_email_time, decrement "email_count"
							logger.info "Sending emails to people who volunteered: #{vol.user.id}"
							unless vol.nil? or vol.user.opted_out_help_email?
								unless vol.user.experimental_condition(assign.course) == "waitlist"
									ReviewMailer.delay.need_review_email(vol.user, assign, review_requests)
									vol.count = vol.count - 1
									vol.last_email_time = Time.now
									vol.save!
								end
							end
						end
					else
						logger.info "Sending emails to people who need it (required)"
						have_to_review_still.each do |h|
							logger.info "Sending emails to people who need it: #{h.user_id}"
							unless h.nil? or h.user.nil? or h.user.opted_out_help_email?
								unless h.user.experimental_condition(assign.course) == "waitlist"
									ReviewMailer.delay.need_review_email(h.user, assign, review_requests)
									h.last_email_time = Time.now
									h.save!
								end
							end
						end
					end
				end
			end
		end
	end
end
