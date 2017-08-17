class EmailsController < ApplicationController

  # FIXME to be able to use distance_of_time_in_words when construction flash messages.
  # since it's a view helper, it's not standard to use it here in the controller.

  include ActionView::Helpers::DateHelper

  skip_before_action :require_login, only: [
                     :unverified,
                     :verify,
                     :new_verification,
                     :create_verification,
                     :verification_sent
                     ], raise: false
  before_action :find_authentication, except: [
                :new,
                :create,
                :unverified,
                :verify,
                :new_verification,
                :create_verification,
                :verification_sent
                ]
  before_action :find_authentication_by_token, only: [:verify]

  def unverified
  end

  def new
    @auth = EmailAuthentication.new
    @auth.user = current_user

    render :new_password unless current_user.has_password?
  end

  def create
    has_password = current_user.has_password?

    @auth = current_user.authentications
            .build params[:email_authentication].merge(type: 'EmailAuthentication')

    unless has_password
      current_user.password = params[:user][:password]
      current_user.password_confirmation = params[:user][:password_confirmation]
      current_user.password_reset_token = nil
    end

    if current_user.save
      @auth.send_verify

      current_user.authentications.emails.each do |e|
        e.destroy unless e.active? || e == @auth
      end

      redirect_to verification_sent_emails_path,
                  notice: t('emails.flash.verification_sent', email: @auth.uid)
    else
      if has_password
        render :new
      else
        render :new_password
      end
    end
  end


  def new_verification
  end

  def create_verification
    @auth = EmailAuthentication.find_by_uid params[:email]
    if @auth
      if @auth.active?
        redirect_to login_path,
                    alert: t('emails.flash.already_verified', email: @auth.uid)
      else
        if @auth.token_created_at > RESEND_WAIT.ago
          @email = @auth.uid
          flash.now.alert = t('.emails.flash.verification_wait',
                              time: distance_of_time_in_words(RESEND_WAIT))

          render :new_verification
        else
          @auth.send_verify
          redirect_to verification_sent_emails_path,
                      notice: t('emails.flash.verification_sent', email: @auth.uid)
        end
      end
    else
      flash.now.alert = t('emails.flash.not_found', email: params[:email])
      render :new_verification
    end
  end

  def verify
    if @user.has_password?
      welcome = @user.authentications.active.empty?
      activate_email

      if welcome
        copy_return_to
        logged_in welcome_account_path, notice: t('emails.flash.verified', email: @auth.uid)
      else
        redirect_to account_path, notice: t('emails.flash.verified', email: @auth.uid)
      end
    else
      render :new_password
    end
  end

  private

  def find_authentication
    @auth = EmailAuthentication.find_by_id! params[:id]
  end

  def find_authentication_by_token
    if params[:token]
      @auth = Authentication.find_by_provider_and_token 'email', params[:token]

      if @auth
        if @auth.token_created_at.nil? || @auth.token_created_at < VALID_TOKEN_PERIOD.ago
          flash[:alert] = t('emails.flash.verification_expired')
        end

        @user = @auth.user
        return
      end
    end

    flash[:alert] = t('emails.flash.verification_not_found')
    redirect_to current_user ? account_path : login_path
  end

  def activate_email
    @auth.activate
    @auth.save!

    @auth.user.authentications.emails.each do |e|
      e.destroy unless e == @auth
    end

    auto_login @user
  end

  def create_dont_set_password
    if @auth.save
      @auth.send_verify
      redirect_to account_path, notice: t('emails.flash.verification_sent', email: @auth.uid)
    else
      render :new
    end
  end

  def create_set_password
    if current_user.update_attributes params[:user].merge({ password_reset_token: nil })
      redirect_to account_path,
                  notice: t('emails.flash.verified_with_password', email: @auth.uid)
    else
      render :new_password
    end
  end
end
