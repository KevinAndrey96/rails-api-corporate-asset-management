module AssignmentSerializer
  def self.call(assignment, include_asset: true)
    data = {
      id: assignment.id,
      employee: EmployeeSerializer.summary(assignment.employee),
      assigned_on: assignment.assigned_on,
      due_on: assignment.due_on,
      returned_on: assignment.returned_on,
      overdue: assignment.overdue?,
      notes: assignment.notes
    }
    data[:asset] = AssetSerializer.summary(assignment.asset) if include_asset
    data
  end
end
