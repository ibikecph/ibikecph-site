class FollowsController < ApplicationController

  before_action :require_user
  before_action :find_followable

  def follow
    if current_user.follow @followable
      render :update
    else
      render nothing: true
    end
  end

  def unfollow
    if current_user.unfollow @followable
      render :update
    else
      render nothing: true
    end
  end

  private

  def follow_params
    params.require(:follow).permit(:active)
  end

  def require_user
    render nothing: true unless current_user
  end

  def find_followable
    return nil unless %w(BlogEntry Issue).include? params[:followable_type]
    @followable = params[:followable_type]
                  .constantize
                  .find params[:followable_id] rescue nil
  end

end
