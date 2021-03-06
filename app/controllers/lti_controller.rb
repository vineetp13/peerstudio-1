require 'oauth/request_proxy/rack_request'
class LtiController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:enroll_in_assignment]
  before_filter :authenticate_user!, only: :complete_enrollment
  assignment_actions = [:enroll_in_assignment]
  before_action :set_assignment, only: assignment_actions
  def enroll_in_assignment
    # this workhorse method has to:
    # - accept incoming LTI connections
    # - Check if the target assignment is LTI-friendly
    # -- If the user logged in, store the LTI credentials in a user assignment join table
    # -- If not, save those credentials temporarily, and ask the user to create an account
    # --- But if the LTI request comes with email and name (e.g. from Coursera),
    # we don't need to ask about accounts. If the account exists, we simply log in
    # If not, after log in, we store credentials
    #redirect to assignment
    @assignment = Assignment.find(lti_params[:id])
    @course = @assignment.course

    provider = IMS::LTI::ToolProvider.new(@course.consumer_key,
      @course.consumer_secret,
      lti_params)
      # provider = IMS::LTI::ToolProvider.new("kaplan",
      # "Z9CMzvIECeo/DogdR26ZnKXJ0pPDWYBYxWsJ3HPPGVg=",
      # lti_params)

      # YEAH, this line is necessary since we're behind a reverse
      # proxy on production, so the rails server thinks we are actually
      # running on http/80.
      # Since the signature is https/443, we need to fool this rack request
      # into believing it's actually on https
      env['rack.url_scheme'] = "https" if Rails.env.production?
      if provider.valid_request?(request, false)
      #Process
      if user_signed_in?
        if @assignment.enroll_with_lti(current_user, lti_params)
          redirect_to @assignment, notice: "Welcome back, #{current_user.name}" and return
        else
          redirect_to @assignment, alert: "We couldn't get your credentials" and return
        end
      end
      if !provider.lis_person_contact_email_primary.blank?
        #at this point, they aren't logged in, but we have their email.
        user = User.find_for_authentication email: provider.lis_person_contact_email_primary
        if !user.nil?
          sign_in(:user, user)
          if @assignment.enroll_with_lti(current_user, lti_params)
            redirect_to @assignment, notice: "Welcome back, #{current_user.name}!" and return
          else
            redirect_to @assignment, alert: "We couldn't get your credentials" and return
          end
        else
          #We can't find this user, even though our provider gave us an email address
          session[:lti_params] = lti_params
          session["user_return_to"] = complete_lti_enrollment_path(@assignment)
          flash[:notice] = "We need additional information to create your Peerstudio account. Please click the sign in button to continue."
          authenticate_user!
        end
      else
        #Our provider didn't send us an email. If the user is already enrolled log them in.
        # else get credentials
        user = @assignment.lti_user(lti_params)
        if user.nil?
          session[:lti_params] = lti_params
          session["user_return_to"] = complete_lti_enrollment_path(@assignment)
          flash[:notice] = "We need additional information to create your Peerstudio account. Please click the sign in button to continue."
          authenticate_user!
        else
          sign_in(:user, user)
          @assignment.enroll_with_lti(current_user, lti_params)
          redirect_to @assignment, notice: "Welcome back, #{current_user.name}!" and return
        end
      end
    else
      redirect_to root_path, alert: "Your LTI request was broken. If you're a student, please let your staff know."
    end
  end

  def guide

    @course = Course.find(lti_params[:id])
    authenticate_user_is_instructor!(@course)
    render layout: "one_column"
  end

  def complete_enrollment
    lti_params = session[:lti_params]
    @assignment = Assignment.find(lti_params[:id])

    if @assignment.enroll_with_lti(current_user, lti_params)
      session[:lti_params] = nil
      redirect_to @assignment, notice: "Welcome back, #{current_user.name}" and return
    else
      session[:lti_params] = nil
      redirect_to @assignment, alert: "We didn't get your LTI credentials. Try again." and return
    end
  end

	private

	def generate_request_xml(score, lis_result_sourcedid)
		return '<?xml version = "1.0" encoding = "UTF-8"?>
            <imsx_POXEnvelopeRequest xmlns = "some_link (may be not required)">
              <imsx_POXHeader>
                <imsx_POXRequestHeaderInfo>
                  <imsx_version>V1.0</imsx_version>
                  <imsx_messageIdentifier>'+SecureRandom.base64(32)+'</imsx_messageIdentifier>
                </imsx_POXRequestHeaderInfo>
              </imsx_POXHeader>
              <imsx_POXBody>
                <replaceResultRequest>
                  <resultRecord>
                    <sourcedGUID>
                      <sourcedId>' +lis_result_sourcedid +'</sourcedId>
                    </sourcedGUID>
                    <result>
                      <resultScore>
                        <language>en-us</language>
                        <textString>'+score.to_s+'</textString>
                      </resultScore>
                    </result>
                  </resultRecord>
                </replaceResultRequest>
              </imsx_POXBody>
            </imsx_POXEnvelopeRequest>'
	end

  def set_assignment
    @assignment = Assignment.find(lti_params[:id])
  end

  def lti_params
    params.permit(:tool_consumer_info_product_family_code,
        :oauth_signature_method,
        :lis_outcome_service_url,
        :tool_consumer_info_version,
        :oauth_signature,
        :resource_link_title,
        :lti_message_type,
        :lis_result_sourcedid,
        :lis_person_name_full,
        :context_label,
        :oauth_consumer_key,
        :user_id,
        :oauth_version,
        :resource_link_id,
        :oauth_callback,
        :lis_person_contact_email_primary,
        :roles,
        :launch_presentation_locale,
        :context_title,
        :tool_consumer_instance_guid,
        :oauth_timestamp,
        :lti_version,
        :ext_basiclti_submit,
        :context_id,
        :oauth_nonce,
        :tool_consumer_instance_description,
        :id)
  end
end
