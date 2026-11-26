require "test_helper"

module Api
  module V1
    class AlertsAndContractTest < ActionDispatch::IntegrationTest
      test "lists compliance alerts with readable messages" do
        api_get api_v1_alerts_path, client: :reader

        assert_equal %w[technical_review overdue_return soat], data.pluck("kind")
        assert_match(/\AEl SOAT del vehículo VEH-0001 vence el \d+ de \w+ de \d{4} \(en 12 días\)\.\z/, data.last["message"])
        assert_equal "Laura Camila Gómez", data.second.dig("employee", "full_name")
        assert_equal({ "today" => Date.current.iso8601, "within_days" => 30 }, response.parsed_body["meta"])
      end

      test "the window is configurable" do
        api_get api_v1_alerts_path, params: { within_days: 0 }

        assert_equal 2, data.size
      end

      test "every api route is documented in the openapi document" do
        spec = YAML.load_file(Rails.root.join("public/openapi.yaml"))
        documented = spec.fetch("paths").flat_map { |path, operations| operations.keys.excluding("parameters").map { |verb| "#{verb.upcase} #{path}" } }
        routed = Rails.application.routes.routes.filter_map do |route|
          path = route.path.spec.to_s.delete_suffix("(.:format)")
          "#{route.verb} #{path.gsub(/:(\w+)/, '{\1}')}" if path.start_with?("/api/v1") && route.verb != "PUT"
        end

        assert_equal "3.1.0", spec["openapi"]
        assert_equal routed.sort, documented.sort
      end
    end
  end
end
