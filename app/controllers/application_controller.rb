class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_shop!
  helper_method :current_shop

  private

  def current_shop
    @current_shop ||= Shop.find_by(id: session[:shop_id]) if session[:shop_id]
  end

  def authenticate_shop!
    redirect_to login_path, alert: "Debes iniciar sesión" unless current_shop
  end
end
