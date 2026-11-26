# A company owned item that can be lent to an employee. Vehicles also carry the mandatory Colombian documents:
# SOAT (Ley 769 de 2002, art. 42) and the technical-mechanical review (art. 51).
class Asset < ApplicationRecord
  TAG_FORMAT = /\A[A-Z]{2,4}-\d{3,6}\z/
  # Cars ABC123 and motorcycles ABC12D, as issued by the RUNT.
  PLATE_FORMAT = /\A[A-Z]{3}(\d{3}|\d{2}[A-Z])\z/

  enum :category, { laptop: 0, desktop: 1, monitor: 2, phone: 3, vehicle: 4 }, validate: true
  enum :status, { available: 0, assigned: 1, maintenance: 2, retired: 3 }, validate: true

  has_many :assignments, dependent: :restrict_with_error
  has_one :open_assignment, -> { open }, class_name: "Assignment", inverse_of: :asset
  has_one :holder, through: :open_assignment, source: :employee

  normalizes :tag, with: ->(value) { value.upcase.gsub(/[^A-Z0-9]/, "").sub(/\A([A-Z]+)(\d+)\z/, '\1-\2') }
  normalizes :plate, with: ->(value) { value.upcase.gsub(/[^A-Z0-9]/, "").presence }
  normalizes :serial_number, with: ->(value) { value.strip.upcase.presence }
  normalizes :brand, :model, with: ->(value) { value.squish }

  validates :tag, presence: true, uniqueness: true, format: { with: TAG_FORMAT }
  validates :brand, presence: true, length: { maximum: 60 }
  validates :model, presence: true, length: { maximum: 80 }
  validates :serial_number, uniqueness: true, allow_nil: true
  validates :purchased_on, presence: true
  validates :purchase_cost, numericality: { only_integer: true, greater_than: 0 }

  with_options if: :vehicle? do
    validates :plate, presence: true, uniqueness: true, format: { with: PLATE_FORMAT }
    validates :soat_expires_on, :technical_review_expires_on, presence: true
  end

  with_options unless: :vehicle? do
    validates :plate, :soat_expires_on, :technical_review_expires_on, absence: true
  end

  validate :status_matches_assignment

  scope :ordered, -> { order(:tag) }

  def self.search(term)
    pattern = "%#{sanitize_sql_like(term.to_s.strip)}%"
    where("tag LIKE :pattern OR brand LIKE :pattern OR model LIKE :pattern OR serial_number LIKE :pattern OR plate LIKE :pattern", pattern: pattern)
  end

  private
    def status_matches_assignment
      return unless will_save_change_to_status? && persisted?

      if assigned? != open_assignment.present?
        errors.add(:status, assigned? ? :assigned_without_assignment : :has_open_assignment)
      end
    end
end
