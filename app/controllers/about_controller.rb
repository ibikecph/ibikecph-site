class AboutController < ApplicationController

  before_action :find_entries

  def index
    @entry = BlogEntry.tagged_with(['about/']).first
    render :show
  end

  def signal
    @entry = BlogEntry.tagged_with(['about/signal']).first
    render :show
  end

  def api
    @entry = BlogEntry.tagged_with(['about/']).first
    render :show
  end

  def faq
    @entry = BlogEntry.tagged_with(['about/']).first
    render :show
  end

  private
  def find_entries
    @entries = BlogEntry.about.includes(:title)
  end

end
