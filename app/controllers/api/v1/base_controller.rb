module Api
  module V1
    # Every endpoint needs a bearer token. Errors follow RFC 9457 (application/problem+json).
    class BaseController < ApplicationController
      include ActionController::HttpAuthentication::Token::ControllerMethods

      PROBLEM_MEDIA_TYPE = "application/problem+json".freeze

      before_action :authenticate_client!

      rate_limit to: 300, within: 1.minute, by: -> { request.authorization.presence || request.remote_ip },
        with: -> { render_problem(:too_many_requests) }

      rescue_from ActiveRecord::RecordNotFound, with: -> { render_problem(:not_found) }
      rescue_from ActionController::ParameterMissing, with: ->(error) { render_problem(:bad_request, detail: error.message) }
      rescue_from ActiveRecord::RecordInvalid, with: ->(error) { render_validation_problem(error.record) }
      rescue_from AssignmentConflict, with: ->(error) { render_problem(:conflict, detail: error.message) }

      private
        attr_reader :current_client

        def authenticate_client!
          @current_client = authenticate_with_http_token { |token, _options| ApiClient.authenticate(token) }
          return render_unauthorized unless current_client

          current_client.touch(:last_used_at) if current_client.last_used_at.nil? || current_client.last_used_at < 5.minutes.ago
        end

        def require_editor!
          render_problem(:forbidden, detail: I18n.t("problems.forbidden.detail")) unless current_client.editor?
        end

        def render_unauthorized
          headers["WWW-Authenticate"] = %(Bearer realm="api")
          render_problem(:unauthorized, detail: I18n.t("problems.unauthorized.detail"))
        end

        def render_validation_problem(record)
          render_problem(:unprocessable_content, detail: record.errors.full_messages.to_sentence, errors: record.errors.to_hash)
        end

        def render_conflict_for(record)
          render_problem(:conflict, detail: record.errors.full_messages.to_sentence)
        end

        def render_problem(status, detail: nil, errors: nil)
          code = Rack::Utils.status_code(status)
          body = { type: "about:blank", title: I18n.t("problems.#{status}.title"), status: code, detail: detail, errors: errors }.compact

          render json: body, status: code, content_type: PROBLEM_MEDIA_TYPE
        end

        def render_page(scope, serializer)
          page = Page.new(scope, number: params[:page], size: params.fetch(:per_page, Page::DEFAULT_SIZE))
          headers["Link"] = pagination_links(page) if page.total_pages > 1

          render json: {
            data: page.records.map { |record| serializer.call(record) },
            meta: { page: page.number, per_page: page.size, total_count: page.total_count, total_pages: page.total_pages }
          }
        end

        def pagination_links(page)
          { first: 1, prev: page.previous_page, next: page.next_page, last: page.total_pages }.filter_map do |rel, number|
            %(<#{request.base_url}#{request.path}?#{request.query_parameters.merge("page" => number).to_query}>; rel="#{rel}") if number
          end.join(", ")
        end

        def sorted(scope, allowed, default)
          key = params[:sort].to_s
          column = allowed.fetch(key.delete_prefix("-"), nil)
          return scope.order(default) unless column

          scope.order(column => key.start_with?("-") ? :desc : :asc, id: :asc)
        end

        def boolean_param(name)
          ActiveModel::Type::Boolean.new.cast(params[name])
        end
    end
  end
end
