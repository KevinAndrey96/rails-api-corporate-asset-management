require "test_helper"

class ComplianceAlertsTest < ActiveSupport::TestCase
  test "reports expired and expiring vehicle documents and overdue returns, most urgent first" do
    alerts = ComplianceAlerts.new.to_a

    assert_equal [ %i[technical_review expired], %i[overdue_return overdue], %i[soat expiring] ], alerts.map { |alert| [ alert.kind, alert.severity ] }
    assert_equal [ -6, -5, 12 ], alerts.map(&:days_left)
    assert_equal employees(:laura), alerts.second.employee
  end

  test "the window only widens the expiring documents" do
    assert_equal 2, ComplianceAlerts.new(window_days: 0).to_a.size
    assert_equal 4, ComplianceAlerts.new(window_days: 180).to_a.size
    assert_equal ComplianceAlerts::MAXIMUM_WINDOW_DAYS, ComplianceAlerts.new(window_days: 10_000).window_days
  end

  test "retired vehicles and returned assets do not raise alerts" do
    assets(:truck).update!(status: :retired)
    AssetReturn.new(assignment: assignments(:laura_laptop)).call

    assert_equal [ :soat ], ComplianceAlerts.new.to_a.map(&:kind)
  end

  test "evaluates against the given day" do
    alerts = ComplianceAlerts.new(today: Date.current + 13, window_days: 0).to_a

    assert_includes alerts.map { |alert| [ alert.kind, alert.severity ] }, %i[soat expired]
  end
end
