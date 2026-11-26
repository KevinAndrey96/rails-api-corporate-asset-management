require "test_helper"

class AssetLifecycleTest < ActiveSupport::TestCase
  test "lending an available asset opens an assignment and marks it assigned" do
    assignment = AssetCheckout.new(asset: assets(:spare), employee: employees(:andres), due_on: Date.current + 15, notes: "Viaje a Medellín").call

    assert_predicate assignment, :persisted?
    assert_predicate assets(:spare).reload, :assigned?
    assert_equal employees(:andres), assets(:spare).holder
  end

  test "assets that are assigned, in maintenance or retired cannot be lent" do
    error = assert_raises(AssignmentConflict) { AssetCheckout.new(asset: assets(:laptop), employee: employees(:andres)).call }
    assert_equal "El activo no está disponible para asignar (estado actual asignado).", error.message

    assert_raises(AssignmentConflict) { AssetCheckout.new(asset: assets(:monitor), employee: employees(:andres)).call }
  end

  test "inactive employees cannot receive assets" do
    error = assert_raises(AssignmentConflict) { AssetCheckout.new(asset: assets(:spare), employee: employees(:sandra)).call }

    assert_equal :employee_inactive, error.reason
  end

  test "an invalid assignment rolls back the status change" do
    assert_raises(ActiveRecord::RecordInvalid) do
      AssetCheckout.new(asset: assets(:spare), employee: employees(:andres), assigned_on: Date.current, due_on: Date.current - 1).call
    end

    assert_predicate assets(:spare).reload, :available?
  end

  test "the database allows a single open assignment per asset" do
    duplicate = Assignment.new(asset: assets(:laptop), employee: employees(:andres), assigned_on: Date.current)

    assert_not duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "returning closes the assignment and puts the asset back in stock" do
    assignment = AssetReturn.new(assignment: assignments(:laura_laptop), notes: "Teclado en buen estado").call

    assert_equal Date.current, assignment.returned_on
    assert_equal "Teclado en buen estado", assignment.notes
    assert_predicate assets(:laptop).reload, :available?
    assert_nil assets(:laptop).holder
  end

  test "damaged returns go to maintenance" do
    AssetReturn.new(assignment: assignments(:laura_laptop), needs_maintenance: true).call

    assert_predicate assets(:laptop).reload, :maintenance?
  end

  test "an assignment cannot be returned twice or before it started" do
    assert_raises(AssignmentConflict) { AssetReturn.new(assignment: assignments(:andres_spare)).call }
    assert_raises(ActiveRecord::RecordInvalid) do
      AssetReturn.new(assignment: assignments(:laura_laptop), returned_on: Date.current - 365).call
    end
    assert_predicate assets(:laptop).reload, :assigned?
  end
end
