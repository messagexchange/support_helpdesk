class SupportHelpdeskSettingController < ApplicationController
  unloadable

  #before_filter :authorize

  def index
  	@settings = SupportHelpdeskSetting.includes(:project, :tracker)

  	respond_to do |format|
  		format.html
  	end
  end

  def new
  	@setting = SupportHelpdeskSetting.new
    get_for_new_edit

  	respond_to do |format|
  		format.html
  	end
  end

  def create
    @setting = SupportHelpdeskSetting.new(params[:support_helpdesk_setting])

    respond_to do |format|
      if @setting.save
        format.html { redirect_to(support_helpdesk_settings_url, :notice => "Support setting successfully created.")}
      else
        format.html {render :action => "new"}
      end
    end
  end

  def edit
    @setting = SupportHelpdeskSetting.find params[:id]
    get_for_new_edit

    respond_to do |format|
      format.html
    end
  end

  def update
    @setting = SupportHelpdeskSetting.find params[:id]

    respond_to do |format|
      if @setting.update_attributes(params[:support_helpdesk_setting])
        format.html { redirect_to(support_helpdesk_settings_url, :notice => "Support setting successfully updated.")}
      else
        format.html {render :action => "edit"}
      end
    end
  end

  def activate
    @setting = SupportHelpdeskSetting.find params[:id]

    if @setting.active == true
      @setting.active = false
    else
      @setting.active = true
    end

    respond_to do |format|
      if @setting.save
        format.html {redirect_to(support_helpdesk_settings_url, :notice => "Setting updated successfully.")}
      else
        format.html {redirect_to(support_helpdesk_settings_url, :error => "Could not update setting.")}
      end
    end
  end

  def destroy
    @setting = SupportHelpdeskSetting.find params[:id]

    @setting.destroy

    respond_to do |format|
      format.html {redirect_to(support_helpdesk_settings_url, :notice => "Setting deleted.")}
    end
  end

  private
  def get_for_new_edit
    @projects = Project.all
    @trackers = Tracker.all
    @issue_custom_fields = CustomField.where(:type => "IssueCustomField")
    @project_custom_fields = CustomField.where(:type => "ProjectCustomField")
    @groups = Group.all
    @users = User.where("type != ?", "AnonymousUser")
    @statuses = IssueStatus.all

    # get list of templates to select for emails
    @template_files = []
    Dir.foreach("#{File.expand_path(File.dirname(__FILE__))}/../views/support_helpdesk_mailer") do |f|
      if not f == '.' and not f == '..'
        name = f.split(".")[0]
        @template_files << [name, name]
      end
    end
  end
end
