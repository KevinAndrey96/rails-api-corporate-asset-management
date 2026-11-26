# Idempotent. BOOTSTRAP_API_TOKEN registers an editor client with a token you choose (minimum 32 characters);
# otherwise issue one with: bin/rails "api_clients:issue[name,editor]".
if (token = ENV["BOOTSTRAP_API_TOKEN"].presence) && !ApiClient.exists?(name: "bootstrap")
  ApiClient.issue!(name: "bootstrap", access: :editor, token: token)
end

return unless ENV.fetch("LOAD_DEMO_DATA", "false") == "true" && Employee.none?

today = Date.current

employees = [
  { document_number: "1020304050", full_name: "Laura Camila Gómez", email: "lgomez@empresa.example", department: "Tecnología" },
  { document_number: "80123456", full_name: "Andrés Felipe Ruiz", email: "aruiz@empresa.example", department: "Comercial" },
  { document_number: "52987654", full_name: "Marta Lucía Herrera", email: "mherrera@empresa.example", department: "Logística" },
  { document_number: "1098765432", full_name: "Julián David Torres", email: "jtorres@empresa.example", department: "Tecnología" },
  { document_number: "43210987", full_name: "Sandra Patricia Ríos", email: "srios@empresa.example", department: "Gerencia", active: false }
].map { |attributes| Employee.create!(attributes) }

assets = [
  { tag: "LAP-0001", category: :laptop, brand: "Lenovo", model: "ThinkPad T14 Gen 5", serial_number: "PF4XK21A", purchased_on: today - 400, purchase_cost: 5_890_000 },
  { tag: "LAP-0002", category: :laptop, brand: "Dell", model: "Latitude 5450", serial_number: "7HQ2M93", purchased_on: today - 220, purchase_cost: 5_250_000 },
  { tag: "LAP-0003", category: :laptop, brand: "Apple", model: "MacBook Air M3", serial_number: "C02ZK1XYMD6M", purchased_on: today - 90, purchase_cost: 6_499_000 },
  { tag: "MON-0001", category: :monitor, brand: "LG", model: "27UP850", serial_number: "304NTPC4B112", purchased_on: today - 300, purchase_cost: 1_850_000 },
  { tag: "CEL-0001", category: :phone, brand: "Samsung", model: "Galaxy A55", serial_number: "R58X20ABCDE", purchased_on: today - 150, purchase_cost: 1_699_000 },
  { tag: "VEH-0001", category: :vehicle, brand: "Renault", model: "Kangoo Zen 2023", plate: "JKL482", purchased_on: today - 700,
    purchase_cost: 92_000_000, soat_expires_on: today + 12, technical_review_expires_on: today + 180 },
  { tag: "VEH-0002", category: :vehicle, brand: "Chevrolet", model: "NHR Reward 2021", plate: "TSM905", purchased_on: today - 1500,
    purchase_cost: 135_000_000, soat_expires_on: today + 200, technical_review_expires_on: today - 6 },
  { tag: "VEH-0003", category: :vehicle, brand: "Yamaha", model: "XTZ 150 2024", plate: "QWE45F", purchased_on: today - 60,
    purchase_cost: 13_900_000, soat_expires_on: today + 300, technical_review_expires_on: today + 670 }
].map { |attributes| Asset.create!(attributes) }.index_by(&:tag)

AssetCheckout.new(asset: assets["LAP-0001"], employee: employees[0], assigned_on: today - 380).call
AssetCheckout.new(asset: assets["LAP-0002"], employee: employees[1], assigned_on: today - 40, due_on: today - 10, notes: "Préstamo para feria comercial").call
AssetCheckout.new(asset: assets["CEL-0001"], employee: employees[1], assigned_on: today - 140).call
AssetCheckout.new(asset: assets["VEH-0001"], employee: employees[2], assigned_on: today - 600).call

returned = AssetCheckout.new(asset: assets["LAP-0003"], employee: employees[3], assigned_on: today - 80, due_on: today - 50).call
AssetReturn.new(assignment: returned, returned_on: today - 52).call

assets["MON-0001"].update!(status: :maintenance)
