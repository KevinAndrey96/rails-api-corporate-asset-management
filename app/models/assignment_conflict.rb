# Raised when a checkout or return request is valid but contradicts the current state of the asset (HTTP 409).
class AssignmentConflict < StandardError
  attr_reader :reason

  def initialize(reason, **interpolations)
    @reason = reason
    super(I18n.t(reason, scope: "conflicts", **interpolations))
  end
end
