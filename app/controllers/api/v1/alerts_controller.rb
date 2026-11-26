module Api
  module V1
    class AlertsController < BaseController
      def index
        alerts = ComplianceAlerts.new(window_days: params.fetch(:within_days, ComplianceAlerts::DEFAULT_WINDOW_DAYS))

        render json: {
          data: alerts.to_a.map { |alert| AlertSerializer.call(alert) },
          meta: { today: alerts.today, within_days: alerts.window_days }
        }
      end
    end
  end
end
