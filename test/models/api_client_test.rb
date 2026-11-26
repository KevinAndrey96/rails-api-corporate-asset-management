require "test_helper"

class ApiClientTest < ActiveSupport::TestCase
  test "issuing a client returns the plain token once and stores only its digest" do
    client, token = ApiClient.issue!(name: "bi", access: :reader)

    assert_operator token.length, :>=, ApiClient::MINIMUM_TOKEN_LENGTH
    assert_equal ApiClient.digest(token), client.token_digest
    assert_not_includes client.attributes.values, token
  end

  test "rejects short tokens" do
    assert_raises(ArgumentError) { ApiClient.issue!(name: "weak", access: :editor, token: "short") }
  end

  test "authenticates active clients only" do
    assert_equal api_clients(:editor), ApiClient.authenticate(ApiRequestHelpers::TOKENS[:editor])
    assert_nil ApiClient.authenticate(ApiRequestHelpers::TOKENS[:revoked])
    assert_nil ApiClient.authenticate("")
    assert_nil ApiClient.authenticate("unknown-token-0123456789abcdefghijklmn")
  end

  test "revoking a client disables its token" do
    api_clients(:reader).revoke!

    assert_nil ApiClient.authenticate(ApiRequestHelpers::TOKENS[:reader])
  end
end
