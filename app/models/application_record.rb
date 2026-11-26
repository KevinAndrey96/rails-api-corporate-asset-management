class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.human_enum(attribute, value)
    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{attribute}/#{value}", default: value.to_s.humanize)
  end
end
