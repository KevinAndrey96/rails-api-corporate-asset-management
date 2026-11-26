class Employee < ApplicationRecord
  has_many :assignments, dependent: :restrict_with_error
  has_many :open_assignments, -> { open }, class_name: "Assignment", inverse_of: :employee
  has_many :assigned_assets, through: :open_assignments, source: :asset

  normalizes :document_number, with: ->(value) { value.gsub(/\D/, "") }
  normalizes :full_name, :department, with: ->(value) { value.squish }
  normalizes :email, with: ->(value) { value.strip.downcase }

  validates :document_number, presence: true, uniqueness: true, format: { with: /\A\d{6,10}\z/ }
  validates :full_name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :department, presence: true, length: { maximum: 80 }
  validate :no_open_assignments_when_deactivated

  scope :ordered, -> { order(:full_name) }
  scope :active, -> { where(active: true) }

  def masked_document_number
    "****#{document_number.last(4)}"
  end

  private
    def no_open_assignments_when_deactivated
      return unless will_save_change_to_active?(from: true, to: false) && open_assignments.exists?

      errors.add(:active, :has_open_assignments)
    end
end
