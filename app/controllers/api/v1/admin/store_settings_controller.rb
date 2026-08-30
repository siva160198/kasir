module Api::V1::Admin
  class StoreSettingsController < ApplicationController
    def show
      setting = StoreSetting.current; authorize setting
      render json: { store_setting: setting_json(setting) }
    end
    def update
      setting = StoreSetting.current; authorize setting
      setting.assign_attributes(setting_params)
      setting.logo.attach(params[:logo]) if params[:logo].present?
      setting.logo.purge if params[:remove_logo].to_s == "true"
      return render_validation_error(setting) unless setting.save
      render json: { store_setting: setting_json(setting) }
    end
    private
      def setting_params = params.permit(:store_name, :address, :phone, :email, :tax_id, :currency, :tax_rate, :prices_include_tax, :rounding_unit, :receipt_width, :receipt_header, :receipt_footer, :show_cashier, :show_sku, :show_tax, :printer_name, :printer_copies)
      def setting_json(setting)
        setting.as_json(only: %i[id store_name address phone email tax_id currency tax_rate prices_include_tax rounding_unit receipt_width receipt_header receipt_footer show_cashier show_sku show_tax printer_name printer_copies]).merge(logo_url: setting.logo.attached? ? "/api/v1/store_profile/logo" : nil)
      end
  end
end
