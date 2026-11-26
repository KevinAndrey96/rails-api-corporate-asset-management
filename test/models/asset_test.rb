require "test_helper"

class AssetTest < ActiveSupport::TestCase
  def build_asset(**attributes)
    Asset.new({ tag: "lap 0003", category: :laptop, brand: "Apple", model: "MacBook Air M3", serial_number: " c02zk1xymd6m ",
      purchased_on: Date.current, purchase_cost: 6_499_000 }.merge(attributes))
  end

  def build_vehicle(**attributes)
    build_asset(tag: "VEH-0009", category: :vehicle, serial_number: nil, plate: "abc-123",
      soat_expires_on: Date.current + 90, technical_review_expires_on: Date.current + 90, **attributes)
  end

  test "normalizes inventory tags, serial numbers and plates" do
    asset = build_asset
    vehicle = build_vehicle

    assert_equal "LAP-0003", asset.tag
    assert_equal "C02ZK1XYMD6M", asset.serial_number
    assert_equal "ABC123", vehicle.plate
    assert_predicate asset, :valid?
    assert_predicate vehicle, :valid?
  end

  test "tags, serial numbers and plates are unique" do
    assert_not build_asset(tag: "LAP-0001").valid?
    assert_not build_asset(serial_number: "pf4xk21a").valid?
    assert_not build_vehicle(plate: "JKL 482").valid?
  end

  test "accepts car and motorcycle plates only" do
    assert_predicate build_vehicle(plate: "QWE45F"), :valid?
    assert_not build_vehicle(plate: "AB1234").valid?
    assert_not build_vehicle(plate: "ABC1234").valid?
  end

  test "vehicles require SOAT and technical review dates, other assets cannot have them" do
    vehicle = build_vehicle(soat_expires_on: nil, technical_review_expires_on: nil)
    laptop = build_asset(plate: "ABC123", soat_expires_on: Date.current)

    assert_not vehicle.valid?
    assert vehicle.errors.added?(:soat_expires_on, :blank)
    assert vehicle.errors.added?(:technical_review_expires_on, :blank)
    assert_not laptop.valid?
    assert laptop.errors.added?(:plate, :present)
  end

  test "rejects unknown categories and non positive costs" do
    assert_not build_asset(category: "printer").valid?
    assert_not build_asset(purchase_cost: 0).valid?
  end

  test "status only becomes assigned through a checkout" do
    spare = assets(:spare)

    assert_not spare.update(status: :assigned)
    assert spare.errors.added?(:status, :assigned_without_assignment)
  end

  test "an assigned asset cannot change its status until it is returned" do
    laptop = assets(:laptop)

    assert_not laptop.update(status: :maintenance)
    assert laptop.errors.added?(:status, :has_open_assignment)
  end

  test "knows its current holder" do
    assert_equal employees(:laura), assets(:laptop).holder
    assert_nil assets(:spare).holder
  end

  test "searches by tag, brand, model, serial number and plate" do
    assert_equal [ assets(:van) ], Asset.search("kangoo").to_a
    assert_equal [ assets(:truck) ], Asset.search("TSM905").to_a
    assert_equal [ assets(:spare) ], Asset.search("7hq2").to_a
    assert_empty Asset.search("100%")
  end
end
