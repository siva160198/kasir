module Api::V1
  class StoreProfilesController < ApplicationController
    def show
      setting = StoreSetting.current
      render json: { store_profile: setting.as_json(only: %i[store_name address phone email tax_id currency receipt_width receipt_header receipt_footer show_cashier show_sku show_tax printer_name printer_copies]).merge(logo_url: setting.logo.attached? ? "/api/v1/store_profile/logo" : nil) }
    end

    def logo
      logo = StoreSetting.current.logo
      return head :not_found unless logo.attached?

      send_data logo.download, type: logo.content_type, disposition: "inline", filename: logo.filename.to_s
    end
  end
end
