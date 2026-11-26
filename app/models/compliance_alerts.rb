# Lists what needs attention: vehicles whose SOAT or technical-mechanical review is expired or about to expire,
# and lent assets that were not returned by their due date.
class ComplianceAlerts
  Alert = Data.define(:kind, :severity, :asset, :due_on, :days_left, :employee)

  DEFAULT_WINDOW_DAYS = 30
  MAXIMUM_WINDOW_DAYS = 365
  VEHICLE_DOCUMENTS = { soat: :soat_expires_on, technical_review: :technical_review_expires_on }.freeze

  attr_reader :today, :window_days

  def initialize(today: Date.current, window_days: DEFAULT_WINDOW_DAYS)
    @today = today
    @window_days = window_days.to_i.clamp(0, MAXIMUM_WINDOW_DAYS)
  end

  def to_a
    (vehicle_document_alerts + overdue_return_alerts).sort_by { |alert| [ alert.days_left, alert.asset.tag ] }
  end

  private
    def vehicle_document_alerts
      horizon = today + window_days
      vehicles = Asset.vehicle.where.not(status: :retired)

      VEHICLE_DOCUMENTS.flat_map do |kind, column|
        vehicles.where(column => ..horizon).map do |vehicle|
          due_on = vehicle.public_send(column)
          Alert.new(kind: kind, severity: due_on < today ? :expired : :expiring, asset: vehicle, due_on: due_on,
            days_left: (due_on - today).to_i, employee: nil)
        end
      end
    end

    def overdue_return_alerts
      Assignment.overdue(today).includes(:asset, :employee).map do |assignment|
        Alert.new(kind: :overdue_return, severity: :overdue, asset: assignment.asset, due_on: assignment.due_on,
          days_left: (assignment.due_on - today).to_i, employee: assignment.employee)
      end
    end
end
