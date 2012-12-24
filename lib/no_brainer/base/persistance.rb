module NoBrainer::Base::Persistance
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :create, :update, :save, :destroy
  end

  # TODO after_initialize callback
  # TODO attr_protected, etc.
  def initialize(attrs={}, options={})
    super
    @new_record = options[:new_record].nil? ? true : options[:new_record]
  end

  def new_record?
    @new_record
  end

  def destroyed?
    !!@destroyed
  end

  def persisted?
    !new_record? && !destroyed?
  end

  def reload
    assign_attributes(selector.run, :prestine => true)
  end

  def update_attributes(attrs)
    assign_attributes(attrs)
    save
  end

  def update_attribute(field, value)
    update_attributes(field => value)
  end

  def save
    run_callbacks(new_record? ? :create : :update) do
      run_callbacks :save do
        if new_record?
          result = NoBrainer.run { table.insert(attributes) }
          self.id ||= result['generated_keys'].first
          @new_record = false
        else
          selector.update { attributes }
        end
        true
      end
    end
  end

  def destroy
    run_callbacks :destroy do
      selector.delete
      @destroyed = true
      # TODO freeze attriutes, etc.
      true
    end
  end

  module ClassMethods
    def create(*args)
      new(*args).tap { |model| model.save }
    end

    def create!(*args)
      new(*args).tap { |model| model.save! }
    end
  end
end
