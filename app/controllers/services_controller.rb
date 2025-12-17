class ServicesController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :set_service, only: [ :destroy, :use ]

  def index
    @services = current_shop.services.order(usage_count: :desc, name: :asc)
  end

  def create
    @service = current_shop.services.build(service_params)

    if @service.save
      redirect_to services_path, notice: "Servicio creado exitosamente."
    else
      @services = current_shop.services.order(usage_count: :desc, name: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy
    redirect_to services_path, notice: "Servicio eliminado."
  end

  def use
    # Quick register: create service record without client/plate
    current_shop.service_records.create!(
      service_name: @service.name,
      price: @service.price,
      service_date: Time.current,
      notes: "Registro rápido"
    )

    # Increment usage count
    @service.increment_usage!

    redirect_to chat_path, notice: "✅ #{@service.name} registrado - $#{number_with_delimiter(@service.price.to_i)}"
  end

  private

  def set_service
    @service = current_shop.services.find(params[:id])
  end

  def service_params
    params.require(:service).permit(:name, :price)
  end
end
