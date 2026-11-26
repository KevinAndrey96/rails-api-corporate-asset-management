# Document numbers are personal data (Ley 1581 de 2012): responses only expose the last four digits.
module EmployeeSerializer
  def self.call(employee, include_assets: false)
    data = {
      id: employee.id,
      document_number: employee.masked_document_number,
      full_name: employee.full_name,
      email: employee.email,
      department: employee.department,
      active: employee.active
    }
    data[:assigned_assets] = employee.assigned_assets.ordered.map { |asset| AssetSerializer.summary(asset) } if include_assets
    data
  end

  def self.summary(employee)
    { id: employee.id, full_name: employee.full_name, department: employee.department }
  end
end
