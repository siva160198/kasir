module Api
  module V1
    module Admin
      class CategoriesController < ApplicationController
        def index
          authorize Category
          categories, pagination = paginate_api(policy_scope(Category), search_columns: %w[name description], sortable_columns: %w[name active created_at], default_sort: :name)
          records = categories.to_a
          counts = Product.where(category_id: records.map(&:id)).group(:category_id).count
          render json: { categories: records.map { |category| category_json(category, products_count: counts.fetch(category.id, 0)) }, pagination: pagination }
        end

        def show
          category = Category.find(params[:id])
          authorize category
          render json: { category: category_json(category) }
        end

        def create
          category = Category.new(category_params)
          authorize category
          return render_validation_error(category) unless category.save
          record_audit("admin.category_created", category, after: category_snapshot(category))
          render json: { category: category_json(category) }, status: :created
        end

        def update
          category = Category.find(params[:id])
          authorize category
          before = category_snapshot(category)
          category.assign_attributes(category_params)
          return render json: { category: category_json(category), unchanged: true } unless category.changed?
          return render_validation_error(category) unless category.save
          record_audit("admin.category_updated", category, before: before, after: category_snapshot(category))
          render json: { category: category_json(category) }
        end

        def destroy
          category = Category.find(params[:id])
          authorize category
          snapshot = category_snapshot(category)
          return render_validation_error(category) unless category.destroy
          AuditLog.record!(action: "admin.category_deleted", actor: Current.user, metadata: { category: snapshot }, request: request)
          head :no_content
        end

        private
          def category_params = params.permit(:name, :description, :active)

          def category_json(category, products_count: nil)
            category.as_json(only: %i[id name description active created_at updated_at]).merge(products_count: products_count.nil? ? category.products.count : products_count)
          end

          def category_snapshot(category) = category.slice("name", "description", "active")

          def record_audit(action, category, metadata)
            AuditLog.record!(action: action, actor: Current.user, auditable: category, metadata: metadata, request: request)
          end
      end
    end
  end
end
