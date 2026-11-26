class Assignment < ApplicationRecord
  belongs_to :asset
  belongs_to :employee

  normalizes :notes, with: ->(value) { value.strip.presence }

  validates :assigned_on, presence: true
  validates :notes, length: { maximum: 500 }
  validates :asset_id, uniqueness: { conditions: -> { open } }, if: :open?
  validate :due_on_not_before_assigned_on
  validate :returned_on_not_before_assigned_on

  scope :open, -> { where(returned_on: nil) }
  scope :returned, -> { where.not(returned_on: nil) }
  scope :overdue, ->(today = Date.current) { open.where(due_on: ...today) }
  scope :recent_first, -> { order(assigned_on: :desc, id: :desc) }

  def open?
    returned_on.nil?
  end

  def overdue?(today = Date.current)
    open? && due_on.present? && due_on < today
  end

  private
    def due_on_not_before_assigned_on
      errors.add(:due_on, :before_assigned_on) if due_on && assigned_on && due_on < assigned_on
    end

    def returned_on_not_before_assigned_on
      errors.add(:returned_on, :before_assigned_on) if returned_on && assigned_on && returned_on < assigned_on
    end
end
