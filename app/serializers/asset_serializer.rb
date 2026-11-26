module AssetSerializer
  def self.call(asset, include_history: false)
    data = {
      id: asset.id,
      tag: asset.tag,
      category: asset.category,
      status: asset.status,
      brand: asset.brand,
      model: asset.model,
      serial_number: asset.serial_number,
      purchased_on: asset.purchased_on,
      purchase_cost: asset.purchase_cost,
      holder: asset.holder && EmployeeSerializer.summary(asset.holder)
    }
    data[:vehicle] = vehicle_documents(asset) if asset.vehicle?
    data[:assignments] = asset.assignments.includes(:employee).recent_first.map { |assignment| AssignmentSerializer.call(assignment, include_asset: false) } if include_history
    data
  end

  def self.summary(asset)
    { id: asset.id, tag: asset.tag, category: asset.category, brand: asset.brand, model: asset.model }
  end

  def self.vehicle_documents(asset)
    { plate: asset.plate, soat_expires_on: asset.soat_expires_on, technical_review_expires_on: asset.technical_review_expires_on }
  end
end
