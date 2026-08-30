module Api
  module V1
    module Admin
      class ProductsController < ApplicationController
        def index
          authorize Product
          products, pagination = paginate_api(policy_scope(Product), search_columns: %w[name sku barcode unit], sortable_columns: %w[name sku cost_price selling_price minimum_stock active created_at], default_sort: :name)
          render json: { products: products.includes(:category).map { |product| product_json(product) }, categories: category_options, pagination: pagination }
        end

        def show
          product = Product.includes(:category).find(params[:id])
          authorize product
          render json: { product: product_json(product), categories: category_options }
        end

        def create
          product = Product.new(product_params)
          authorize product
          return render_validation_error(product) unless product.save
          record_audit("admin.product_created", product, after: product_snapshot(product))
          render json: { product: product_json(product) }, status: :created
        end

        def update
          product = Product.find(params[:id])
          authorize product
          before = product_snapshot(product)
          product.assign_attributes(product_params)
          return render json: { product: product_json(product), unchanged: true } unless product.changed?
          return render_validation_error(product) unless product.save
          record_audit("admin.product_updated", product, before: before, after: product_snapshot(product))
          render json: { product: product_json(product) }
        end

        def destroy
          product = Product.find(params[:id])
          authorize product
          snapshot = product_snapshot(product)
          product.destroy!
          AuditLog.record!(action: "admin.product_deleted", actor: Current.user, metadata: { product: snapshot }, request: request)
          head :no_content
        end

        private
          def product_params
            params.permit(:category_id, :name, :sku, :barcode, :cost_price, :selling_price, :minimum_stock, :unit, :active)
          end

          def product_json(product)
            product.as_json(only: %i[id category_id name sku barcode cost_price selling_price minimum_stock unit active created_at updated_at]).merge(category_name: product.category.name)
          end

          def category_options
            Category.order(:name).select(:id, :name, :active).as_json(only: %i[id name active])
          end

          def product_snapshot(product)
            product.slice("category_id", "name", "sku", "barcode", "cost_price", "selling_price", "minimum_stock", "unit", "active")
          end

          def record_audit(action, product, metadata)
            AuditLog.record!(action: action, actor: Current.user, auditable: product, metadata: metadata, request: request)
          end
      end
    end
  end
end
