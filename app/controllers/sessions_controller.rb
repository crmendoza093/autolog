class SessionsController < ApplicationController
  skip_before_action :authenticate_shop!, only: [ :new, :create ]
  layout "authentication"

  def new
    redirect_to root_path if current_shop
  end

  def create
    shop = Shop.find_by(name: params[:shop_name])

    if shop&.authenticate_pin(params[:pin])
      session[:shop_id] = shop.id
      shop.update_column(:last_login_at, Time.current)
      redirect_to root_path, notice: "Bienvenido a #{shop.name}"
    else
      flash.now[:alert] = "PIN o nombre de taller incorrecto"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:shop_id)
    redirect_to login_path, notice: "Sesión cerrada"
  end
end
