# Lends an available asset to an active employee. The asset row is locked so two concurrent requests cannot both win;
# the partial unique index on open assignments is the last line of defense.
class AssetCheckout
  def initialize(asset:, employee:, assigned_on: Date.current, due_on: nil, notes: nil)
    @asset = asset
    @employee = employee
    @assigned_on = assigned_on
    @due_on = due_on
    @notes = notes
  end

  def call
    Asset.transaction do
      @asset.lock!
      raise AssignmentConflict.new(:asset_not_available, status: Asset.human_enum(:status, @asset.status)) unless @asset.available?
      raise AssignmentConflict.new(:employee_inactive) unless @employee.active?

      assignment = @asset.assignments.create!(employee: @employee, assigned_on: @assigned_on, due_on: @due_on, notes: @notes)
      @asset.update!(status: :assigned)
      assignment
    end
  rescue ActiveRecord::RecordNotUnique
    raise AssignmentConflict.new(:asset_not_available, status: Asset.human_enum(:status, "assigned"))
  end
end
