require "test_helper"

module Api
  module V1
    class AssetsControllerTest < ActionDispatch::IntegrationTest
      test "lists assets filtered by category, status and text, sorted on whitelisted columns" do
        api_get api_v1_assets_path, params: { category: "vehicle", sort: "-purchase_cost" }
        assert_equal %w[VEH-0002 VEH-0001], data.pluck("tag")
        assert_equal "TSM905", data.first.dig("vehicle", "plate")

        api_get api_v1_assets_path, params: { status: "assigned" }
        assert_equal [ [ "LAP-0001", "Laura Camila Gómez" ] ], data.map { |asset| [ asset["tag"], asset.dig("holder", "full_name") ] }

        api_get api_v1_assets_path, params: { q: "dell", sort: "id; DROP TABLE assets" }
        assert_equal [ "LAP-0002" ], data.pluck("tag")
      end

      test "shows an asset with its assignment history" do
        api_get api_v1_asset_path(assets(:spare))

        assert_equal [ "Andrés Felipe Ruiz" ], data["assignments"].map { |assignment| assignment.dig("employee", "full_name") }
        assert_not data.key?("vehicle")
      end

      test "registers vehicles with their mandatory documents" do
        api_write :post, api_v1_assets_path, { asset: { tag: "veh-0003", category: "vehicle", brand: "Yamaha", model: "XTZ 150", plate: "qwe 45f",
          purchased_on: "2026-09-01", purchase_cost: 13_900_000, soat_expires_on: "2027-09-01", technical_review_expires_on: "2028-09-01", status: "assigned" } }

        assert_response :created
        assert_equal [ "VEH-0003", "available", "QWE45F" ], [ data["tag"], data["status"], data.dig("vehicle", "plate") ]
      end

      test "rejects vehicles without documents" do
        api_write :post, api_v1_assets_path, { asset: { tag: "VEH-0004", category: "vehicle", brand: "Kia", model: "Picanto", purchased_on: "2026-09-01", purchase_cost: 60_000_000 } }

        assert_problem :unprocessable_content, "Datos inválidos"
        assert_equal %w[plate soat_expires_on technical_review_expires_on], response.parsed_body["errors"].keys.sort
      end

      test "sends available assets to maintenance but not assigned ones" do
        api_write :patch, api_v1_asset_path(assets(:spare)), { asset: { status: "maintenance" } }
        assert_equal "maintenance", data["status"]

        api_write :patch, api_v1_asset_path(assets(:laptop)), { asset: { status: "retired" } }
        assert_problem :unprocessable_content, "Datos inválidos"
      end

      test "only assets without history can be deleted" do
        api_write :delete, api_v1_asset_path(assets(:spare))
        assert_problem :conflict, "Conflicto con el estado actual"

        api_write :delete, api_v1_asset_path(assets(:monitor))
        assert_response :no_content
      end
    end
  end
end
