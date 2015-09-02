class Api::V1::PrivacyTokensController < Api::V1::BaseController
  def create
    @token = PrivacyToken.new token_params

    @token.save ? success : error
  end

  def show
    @token = PrivacyToken.new token_params

    @token.valid? ? success : error
  end

  def update
    @token = PrivacyToken.find_by_email_and_password(params[:user][:email], params[:user][:old_password])

    if @token
      @token.update_attributes(token_params) ? success : error
    else
      not_found
    end
  end

  private

  def token_params
    params.require(:user).permit(:email, :password)
  end

  def success
    render status: 201,
           json: {
               success: true,
               info: {},
               data: { signature: @token.signature }
           }
  end

  def error
    render status: 400,
           json: {
               success: false,
               info: {},
               data: { errors: @token.errors.full_messages }
           }
  end

  def not_found
    render status: 404,
           json: {
               success: false,
               info: {},
               data: {}
           }
  end

end