module Api
  module V1
    class AssetsController < BaseController
      SORTABLE = { "tag" => :tag, "purchased_on" => :purchased_on, "purchase_cost" => :purchase_cost }.freeze

      before_action :require_editor!, only: %i[create update destroy]
      before_action :set_asset, only: %i[show update destroy]

      def index
        assets = Asset.includes(:holder)
        assets = assets.where(category: params[:category]) if Asset.categories.key?(params[:category])
        assets = assets.where(status: params[:status]) if Asset.statuses.key?(params[:status])
        assets = assets.search(params[:q]) if params[:q].present?

        render_page sorted(assets, SORTABLE, :tag), AssetSerializer
      end

      def show
        render json: { data: AssetSerializer.call(@asset, include_history: true) }
      end

      def create
        asset = Asset.create!(asset_params.except(:status))

        render json: { data: AssetSerializer.call(asset) }, status: :created, location: api_v1_asset_url(asset)
      end

      def update
        @asset.update!(asset_params)

        render json: { data: AssetSerializer.call(@asset) }
      end

      def destroy
        return head :no_content if @asset.destroy

        render_conflict_for(@asset)
      end

      private
        def set_asset
          @asset = Asset.find(params.expect(:id))
        end

        def asset_params
          params.expect(asset: %i[tag category status brand model serial_number purchased_on purchase_cost plate soat_expires_on technical_review_expires_on])
        end
    end
  end
end
