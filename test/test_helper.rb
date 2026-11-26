ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all
  end
end

module ApiRequestHelpers
  TOKENS = {
    editor: "editor-token-0123456789abcdefghijklmnop",
    reader: "reader-token-0123456789abcdefghijklmnop",
    revoked: "revoked-token-0123456789abcdefghijklmno"
  }.freeze

  def auth_headers(client = :editor)
    { "Authorization" => "Bearer #{TOKENS.fetch(client)}", "Accept" => "application/json" }
  end

  def api_get(path, client: :editor, params: {})
    get path, params: params, headers: auth_headers(client)
  end

  def api_write(method, path, body = {}, client: :editor)
    public_send(method, path, params: body, headers: auth_headers(client), as: :json)
  end

  def data
    response.parsed_body.fetch("data")
  end

  def assert_problem(status, title)
    assert_response status
    assert_equal "application/problem+json", response.media_type
    assert_equal Rack::Utils.status_code(status), response.parsed_body["status"]
    assert_equal title, response.parsed_body["title"]
  end
end

ActionDispatch::IntegrationTest.include(ApiRequestHelpers)
