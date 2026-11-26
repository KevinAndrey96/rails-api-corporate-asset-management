module AlertSerializer
  def self.call(alert)
    {
      kind: alert.kind,
      severity: alert.severity,
      message: I18n.t(alert.kind, scope: [ "alerts", alert.severity ], tag: alert.asset.tag, days: alert.days_left.abs, date: I18n.l(alert.due_on, format: :long)),
      due_on: alert.due_on,
      days_left: alert.days_left,
      asset: AssetSerializer.summary(alert.asset).merge(plate: alert.asset.plate).compact,
      employee: alert.employee && EmployeeSerializer.summary(alert.employee)
    }.compact
  end
end
