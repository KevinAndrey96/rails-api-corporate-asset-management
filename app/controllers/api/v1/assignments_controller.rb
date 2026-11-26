module Api
  module V1
    class AssignmentsController < BaseController
      before_action :require_editor!, only: %i[create check_in]

      def index
        assignments = Assignment.includes(:asset, :employee).recent_first
        assignments = assignments.where(asset_id: params[:asset_id]) if params[:asset_id].present?
        assignments = assignments.where(employee_id: params[:employee_id]) if params[:employee_id].present?
        assignments = filter_by_state(assignments)

        render_page assignments, AssignmentSerializer
      end

      def show
        render json: { data: AssignmentSerializer.call(Assignment.find(params.expect(:id))) }
      end

      def create
        attributes = params.expect(assignment: %i[asset_id employee_id assigned_on due_on notes])
        assignment = AssetCheckout.new(
          asset: Asset.find(attributes.require(:asset_id)),
          employee: Employee.find(attributes.require(:employee_id)),
          assigned_on: attributes[:assigned_on].presence || Date.current,
          due_on: attributes[:due_on],
          notes: attributes[:notes]
        ).call

        render json: { data: AssignmentSerializer.call(assignment) }, status: :created, location: api_v1_assignment_url(assignment)
      end

      def check_in
        attributes = params.fetch(:assignment, {}).permit(:returned_on, :needs_maintenance, :notes)
        assignment = AssetReturn.new(
          assignment: Assignment.find(params.expect(:id)),
          returned_on: attributes[:returned_on].presence || Date.current,
          needs_maintenance: ActiveModel::Type::Boolean.new.cast(attributes[:needs_maintenance]) || false,
          notes: attributes[:notes]
        ).call

        render json: { data: AssignmentSerializer.call(assignment) }
      end

      private
        def filter_by_state(assignments)
          case params[:state]
          when "open" then assignments.open
          when "returned" then assignments.returned
          when "overdue" then assignments.overdue
          else assignments
          end
        end
    end
  end
end
