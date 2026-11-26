require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  def build_employee(**attributes)
    Employee.new({ document_number: "1.032.456.789", full_name: "  Paula   Andrea Díaz ", email: " PDiaz@Empresa.Example ", department: "Talento Humano" }.merge(attributes))
  end

  test "normalizes the document number, name and email" do
    employee = build_employee

    assert_predicate employee, :valid?
    assert_equal "1032456789", employee.document_number
    assert_equal "Paula Andrea Díaz", employee.full_name
    assert_equal "pdiaz@empresa.example", employee.email
  end

  test "document numbers have 6 to 10 digits and are unique" do
    assert_not build_employee(document_number: "12345").valid?
    assert_not build_employee(document_number: "12345678901").valid?
    assert_not build_employee(document_number: employees(:laura).document_number).valid?
  end

  test "emails are unique and well formed" do
    assert_not build_employee(email: "LGOMEZ@empresa.example").valid?
    assert_not build_employee(email: "sin-arroba").valid?
  end

  test "cannot be deactivated while holding assets" do
    laura = employees(:laura)

    assert_not laura.update(active: false)
    assert laura.errors.added?(:active, :has_open_assignments)
    assert employees(:andres).update(active: false)
  end

  test "exposes only the last four digits of the document" do
    assert_equal "****4050", employees(:laura).masked_document_number
  end

  test "lists the assets it currently holds" do
    assert_equal [ assets(:laptop) ], employees(:laura).assigned_assets.to_a
    assert_empty employees(:andres).assigned_assets
  end

  test "employees with assignment history cannot be deleted" do
    assert_not employees(:andres).destroy
    assert build_employee.tap(&:save!).destroy
  end
end
