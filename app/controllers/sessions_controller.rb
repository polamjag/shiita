class SessionsController < ApplicationController
  def callback
    user = User.find_or_create_from_auth(request.env['omniauth.auth'])
    session[:uid] = user.uid
    flash[:notice] = "Success to login as #{user.name}."
    redirect_to root_path
  end

  def destroy
    reset_session
    flash[:notice] = "Success to logout."
    redirect_to root_path
  end

  def local_login
    session[:uid] = User.find_by(uid: Shiita::Application.config.local_uid).uid
    flash[:notice] = "Local logged in."
    redirect_to root_path
  end
end
