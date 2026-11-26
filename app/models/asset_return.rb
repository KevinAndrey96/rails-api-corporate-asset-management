# Closes an open assignment and puts the asset back in stock, or in maintenance when it comes back damaged.
class AssetReturn
  def initialize(assignment:, returned_on: Date.current, needs_maintenance: false, notes: nil)
    @assignment = assignment
    @returned_on = returned_on
    @needs_maintenance = needs_maintenance
    @notes = notes
  end

  def call
    Assignment.transaction do
      @assignment.lock!
      raise AssignmentConflict.new(:already_returned, returned_on: I18n.l(@assignment.returned_on, format: :long)) unless @assignment.open?

      @assignment.update!(returned_on: @returned_on, notes: [ @assignment.notes, @notes ].compact_blank.join("\n").presence)
      @assignment.asset.update!(status: @needs_maintenance ? :maintenance : :available)
      @assignment
    end
  end
end
