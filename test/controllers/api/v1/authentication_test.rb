require "test_helper"

module Api
  module V1
    class AuthenticationTest < ActionDispatch::IntegrationTest
      test "requests without a valid token get a 401 problem with a bearer challenge" do
        get api_v1_assets_path

        assert_problem :unauthorized, "No autenticado"
        assert_equal %(Bearer realm="api"), response.headers["WWW-Authenticate"]

        api_get api_v1_assets_path, client: :revoked
        assert_problem :unauthorized, "No autenticado"
      end

      test "reader tokens can read but not write" do
        api_get api_v1_assets_path, client: :reader
        assert_response :success

        api_write :post, api_v1_employees_path, { employee: { full_name: "X" } }, client: :reader
        assert_problem :forbidden, "Acceso denegado"

        api_write :patch, return_api_v1_assignment_path(assignments(:laura_laptop)), {}, client: :reader
        assert_problem :forbidden, "Acceso denegado"
      end

      test "records when a client last used the api" do
        api_get api_v1_alerts_path

        assert_in_delta Time.current, api_clients(:editor).reload.last_used_at, 5.seconds
      end

      test "the health check and the openapi document are public" do
        get rails_health_check_path
        assert_response :success

        get "/openapi.yaml"
        assert_response :success
      end
    end
  end
end
