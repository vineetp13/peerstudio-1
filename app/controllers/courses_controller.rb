class CoursesController < ApplicationController
  # before_filter authenticate_user! except: :index
  before_action :set_course, only: [:show, :edit, :update, :destroy, :regenerate_consumer_secret, :enroll_lti]
  skip_before_filter :verify_authenticity_token, :only => [:enroll_lti]
  # GET /courses
  # GET /courses.json
  def index
    @courses = Course.where(hidden: false)
  end

  # GET /courses/1
  # GET /courses/1.json
  def show
  end

  # GET /courses/new
  def new
    @course = Course.new(user: current_user)
  end

  # GET /courses/1/edit
  def edit
  end

  # POST /courses
  # POST /courses.json
  def create
    @course = Course.new(course_params)
    @course.user = current_user

    respond_to do |format|
      if @course.save
        format.html { redirect_to @course, notice: 'Course was successfully created.' }
        format.json { render action: 'show', status: :created, location: @course }
      else
        format.html { render action: 'new' }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /courses/1
  # PATCH/PUT /courses/1.json
  def update
    respond_to do |format|
      if @course.update(course_params)
        format.html { redirect_to @course, notice: 'Course was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit', alert: 'There was trouble saving your changes.' }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1
  # DELETE /courses/1.json
  def destroy
    @course.destroy
    respond_to do |format|
      format.html { redirect_to courses_url }
      format.json { head :no_content }
    end
  end

  def about
    render layout: "one_column"
  end

  def regenerate_consumer_secret
    @course.regenerate_consumer_secret!
    redirect_to edit_course_path(@course)
  end

  def enroll_lti
    user = @course.enroll_with_lti(request)
    if user
      sign_in(:user, user)
      if user.consented.nil?
        redirect_to @course, notice: "TODO Consent"
      else
        
        redirect_to @course, notice: "Enrollment successful"
      end
    else
      raise params.inspect
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_course
      @course = Course.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def course_params
      params.require(:course).permit(:title, :institution, :hidden, :open_enrollment, :user_id, :photo,
        :consumer_key,
        #All the LTI params
        :tool_consumer_info_product_family_code,
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
