require 'csv'

class SessionsController < ApplicationController
  skip_before_filter :authorize_action, :only => [:create, :thanks, :csv]
  helper_method :sort_column, :sort_direction

  def index
    if sort_column=="reviewcount"
      @sessions = Session.all.sort { 
        |s1, s2| 
        size_compare = (s1.reviews.size <=> s2.reviews.size) 
        size_compare==0 ? (s1.created_at <=> s2.created_at) : size_compare
      } 
      @sessions = sort_direction=="asc" ? @sessions :  @sessions.reverse 
    elsif sort_column=="presenters"
      @sessions = Session.all.sort_by { |s| s.presenter_names.upcase }  
      @sessions = sort_direction=="asc" ? @sessions :  @sessions.reverse 
    elsif sort_column=="voted"
      @sessions = Session.all.sort { 
        |s1, s2| 
        size_compare =  ( (s1.presenter_has_voted_for? current_presenter.id).to_s <=> (s2.presenter_has_voted_for? current_presenter.id).to_s )
        size_compare==0 ? (s1.created_at <=> s2.created_at) : size_compare
      } 
      @sessions = sort_direction=="asc" ? @sessions :  @sessions.reverse 
    else
      @sessions = Session.order( "upper("+sort_column+") " + sort_direction)
    end
  end

  def show
    @session = Session.find(params[:id])
    @current_presenter_has_voted_for_this_session = Vote.presenter_has_voted_for?(current_presenter.id, params[:id]) 
    @my_vote = Vote.vote_of_presenter_for(current_presenter.id, params[:id]) 
    
    respond_to do |format|
      format.html { render }
      format.json { render json: @session }
      format.pdf do 
        file_name = "tmp/session_#{@session.id}.pdf"
        pdf = @session.generate_pdf(file_name)
        send_file( file_name)
      end
    end
  end

  def program_board_card
    @session = Session.find(params[:id])
    
    respond_to do |format|
      format.pdf do 
        file_name = "tmp/session_#{@session.id}.pdf"
        pdf = @session.generate_program_board_card_pdf(file_name)
        send_file( file_name)
      end
    end
  end

  def public
    @session = Session.find(params[:id])
    if !@session.in_active_program?
      raise "no valid session"
    end
    respond_to do |format|
      format.html { render :layout => 'public' } # public.html.erb
      format.json { render json: @session }
    end
  end

  def new
    #if !PropileConfig.submit_session_active? then raise "Session submission is closed" end
    @session = Session.new
  end

  def edit
    @session = Session.find(params[:id])
  end

  def thanks
    @session = Session.find(params[:id])
  end

  def csv 
    @sessions = Session.all
    session_csv = CSV.generate(options = { :col_sep => ';' }) do |csv| 
      #header row
      csv << [ "Title", "Subtitle",
               "Presenters", "Created", "Modified", 
               "Type", "Topic", "Duration", 
               "Reviews", 
               "Goal", 
               "Intended Audience", "Experience Level", 
               "Max participants", "Laptops", "Other limitations", "Room setup", "Materials", 
               "Short" ]
      #data row
      @sessions.each do |session| 
        csv << [ session.title, session.sub_title, 
                 session.presenter_names, session.created_at, session.updated_at,
                 session.session_type, session.topic, session.duration, 
                 session.reviews.size,
                 session.session_goal, 
                 session.intended_audience, session.experience_level,
                 session.max_participants, session.laptops_required, session.other_limitations, session.room_setup, session.materials_needed,
                 session.short_description
               ]
      end
    end
    send_data(session_csv, :type => 'test/csv', :filename => 'sessions.csv') 
  end

  def pcm_cards
    @sessions = Session.all
    render :layout => 'pcm_cards'
  end

  def create
    @session = Session.new(params[:session])
    unless Captcha.verified?(self)
      flash[:alert]  = I18n.t('sessions.captcha_error')
      render :action => 'new'
      return
    end
    if @session.save
      redirect_to thanks_session_path(@session), notice: 'Session was successfully created.' 
      @session.presenters.each { |presenter| Postman.deliver(:session_submit, presenter, @session) }
    else
      render action: "new"
    end
  end

  def update
    @session = Session.find(params[:id])

    if @session.update_attributes(params[:session])
      redirect_to @session, notice: 'Session was successfully updated.' 
    else
      render action: "edit" 
    end
  end

  def destroy
    @session = Session.find(params[:id])
    @session.destroy

    redirect_to sessions_url 
  end


  def sort_column
    params[:sort] ? params[:sort] : "reviewcount"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end
