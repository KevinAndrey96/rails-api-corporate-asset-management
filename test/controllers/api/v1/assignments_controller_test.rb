require "test_helper"

module Api
  module V1
    class AssignmentsControllerTest < ActionDispatch::IntegrationTest
      test "lends an asset and returns its location" do
        api_write :post, api_v1_assignments_path, { assignment: { asset_id: assets(:van).id, employee_id: employees(:andres).id, due_on: (Date.current + 3).iso8601 } }

        assert_response :created
        assert_equal api_v1_assignment_url(data["id"]), response.location
        assert_equal [ "VEH-0001", Date.current.iso8601, false ], [ data.dig("asset", "tag"), data["assigned_on"], data["overdue"] ]
        assert_predicate assets(:van).reload, :assigned?
      end

      test "lending an assigned asset is a conflict" do
        api_write :post, api_v1_assignments_path, { assignment: { asset_id: assets(:laptop).id, employee_id: employees(:andres).id } }

        assert_problem :conflict, "Conflicto con el estado actual"
        assert_equal "El activo no está disponible para asignar (estado actual asignado).", response.parsed_body["detail"]
      end

      test "lending to an unknown employee is a 404 and a missing asset id is a bad request" do
        api_write :post, api_v1_assignments_path, { assignment: { asset_id: assets(:van).id, employee_id: 0 } }
        assert_problem :not_found, "Recurso no encontrado"

        api_write :post, api_v1_assignments_path, { assignment: { employee_id: employees(:andres).id } }
        assert_problem :bad_request, "Solicitud inválida"
      end

      test "invalid dates are validation problems" do
        api_write :post, api_v1_assignments_path, { assignment: { asset_id: assets(:van).id, employee_id: employees(:andres).id, assigned_on: "2026-10-10", due_on: "2026-10-01" } }

        assert_problem :unprocessable_content, "Datos inválidos"
        assert_equal [ "due_on" ], response.parsed_body["errors"].keys
        assert_predicate assets(:van).reload, :available?
      end

      test "registers returns, optionally to maintenance, only once" do
        api_write :patch, return_api_v1_assignment_path(assignments(:laura_laptop)), { assignment: { needs_maintenance: true, notes: "Pantalla rayada" } }

        assert_response :success
        assert_equal Date.current.iso8601, data["returned_on"]
        assert_predicate assets(:laptop).reload, :maintenance?

        api_write :patch, return_api_v1_assignment_path(assignments(:laura_laptop))
        assert_problem :conflict, "Conflicto con el estado actual"
      end

      test "filters by state, asset and employee" do
        api_get api_v1_assignments_path, params: { state: "overdue" }
        assert_equal [ [ assignments(:laura_laptop).id, true ] ], data.map { |assignment| [ assignment["id"], assignment["overdue"] ] }

        api_get api_v1_assignments_path, params: { state: "returned", employee_id: employees(:andres).id }
        assert_equal [ assignments(:andres_spare).id ], data.pluck("id")

        api_get api_v1_assignment_path(assignments(:andres_spare))
        assert_equal "LAP-0002", data.dig("asset", "tag")
      end
    end
  end
end
