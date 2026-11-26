require "test_helper"

module Api
  module V1
    class EmployeesControllerTest < ActionDispatch::IntegrationTest
      test "lists employees with filters, sorting and masked documents" do
        api_get api_v1_employees_path

        assert_equal [ "Andrés Felipe Ruiz", "Laura Camila Gómez", "Sandra Patricia Ríos" ], data.pluck("full_name")
        assert_equal "****4050", data.second["document_number"]
        assert_no_match "1020304050", response.body

        api_get api_v1_employees_path, params: { active: "false" }
        assert_equal [ "Sandra Patricia Ríos" ], data.pluck("full_name")

        api_get api_v1_employees_path, params: { document_number: "1.020.304.050" }
        assert_equal [ employees(:laura).id ], data.pluck("id")

        api_get api_v1_employees_path, params: { q: "ruiz", sort: "-full_name" }
        assert_equal [ "Andrés Felipe Ruiz" ], data.pluck("full_name")
      end

      test "paginates with meta and an RFC 8288 Link header" do
        api_get api_v1_employees_path, params: { per_page: 2, page: 2, department: "" }

        assert_equal({ "page" => 2, "per_page" => 2, "total_count" => 3, "total_pages" => 2 }, response.parsed_body["meta"])
        assert_match %r{<http://www.example.com/api/v1/employees\?department=&page=1&per_page=2>; rel="prev"}, response.headers["Link"]
        assert_no_match(/rel="next"/, response.headers["Link"])
      end

      test "shows an employee with the assets they hold" do
        api_get api_v1_employee_path(employees(:laura))

        assert_equal [ "LAP-0001" ], data["assigned_assets"].pluck("tag")
      end

      test "creates employees and reports validation errors per field" do
        api_write :post, api_v1_employees_path, { employee: { document_number: "1032456789", full_name: "Paula Díaz", email: "pdiaz@empresa.example", department: "Talento Humano" } }

        assert_response :created
        assert_equal api_v1_employee_url(data["id"]), response.location

        api_write :post, api_v1_employees_path, { employee: { document_number: "12", full_name: "", email: "pdiaz@empresa.example", department: "X" } }
        assert_problem :unprocessable_content, "Datos inválidos"
        assert_equal %w[document_number email full_name], response.parsed_body["errors"].keys.sort
      end

      test "a missing payload is a bad request" do
        api_write :post, api_v1_employees_path, { name: "x" }

        assert_problem :bad_request, "Solicitud inválida"
      end

      test "deactivating an employee with assets is rejected" do
        api_write :patch, api_v1_employee_path(employees(:laura)), { employee: { active: false } }

        assert_problem :unprocessable_content, "Datos inválidos"
        assert_match "activos asignados", response.parsed_body["detail"]
      end

      test "employees with history cannot be deleted" do
        api_write :delete, api_v1_employee_path(employees(:andres))
        assert_problem :conflict, "Conflicto con el estado actual"

        api_write :delete, api_v1_employee_path(employees(:sandra))
        assert_response :no_content
      end

      test "unknown employees are a 404 problem" do
        api_get api_v1_employee_path(id: 0)

        assert_problem :not_found, "Recurso no encontrado"
      end
    end
  end
end
