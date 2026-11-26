module Api
  module V1
    class EmployeesController < BaseController
      SORTABLE = { "full_name" => :full_name, "department" => :department, "created_at" => :created_at }.freeze

      before_action :require_editor!, only: %i[create update destroy]
      before_action :set_employee, only: %i[show update destroy]

      def index
        employees = Employee.all
        employees = employees.where(department: params[:department]) if params[:department].present?
        employees = employees.where(active: boolean_param(:active)) if params.key?(:active)
        employees = employees.where(document_number: params[:document_number].to_s.gsub(/\D/, "")) if params[:document_number].present?
        if params[:q].present?
          employees = employees.where("full_name LIKE :pattern OR email LIKE :pattern", pattern: "%#{Employee.sanitize_sql_like(params[:q].strip)}%")
        end

        render_page sorted(employees, SORTABLE, :full_name), EmployeeSerializer
      end

      def show
        render json: { data: EmployeeSerializer.call(@employee, include_assets: true) }
      end

      def create
        employee = Employee.create!(employee_params)

        render json: { data: EmployeeSerializer.call(employee) }, status: :created, location: api_v1_employee_url(employee)
      end

      def update
        @employee.update!(employee_params)

        render json: { data: EmployeeSerializer.call(@employee) }
      end

      def destroy
        return head :no_content if @employee.destroy

        render_conflict_for(@employee)
      end

      private
        def set_employee
          @employee = Employee.find(params.expect(:id))
        end

        def employee_params
          params.expect(employee: %i[document_number full_name email department active])
        end
    end
  end
end
