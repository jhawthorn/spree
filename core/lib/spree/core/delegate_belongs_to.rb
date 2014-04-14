##
# Creates methods on object which delegate to an association proxy.
# see delegate_belongs_to for two uses
#
# Todo - integrate with ActiveRecord::Dirty to make sure changes to delegate object are noticed
# Should do
# class User < Spree::Base; delegate_belongs_to :contact, :firstname; end
# class Contact < Spree::Base; end
# u = User.first
# u.changed? # => false
# u.firstname = 'Bobby'
# u.changed? # => true
#
# Right now the second call to changed? would return false
#
# Todo - add has_one support. fairly straightforward addition
##
module DelegateBelongsTo
  extend ActiveSupport::Concern

  module ClassMethods

    ##
    # Creates methods for accessing and setting attributes on an association.  Uses same
    # default list of attributes as delegates_to_association.
    # @todo Integrate this with ActiveRecord::Dirty, so if you set a property through one of these setters and then call save on this object, it will save the associated object automatically.
    ##
    def delegate_belongs_to(association, *attrs)
      if attrs.empty? || attrs.include?(:defaults)
        raise "delegate_belongs_to: default attrs no longer supported"
      end
      opts = attrs.extract_options!
      attrs.each do |attr|
        define_method attr do |*args|
          send(:delegator_for, association, attr, *args)
        end

        define_method "#{attr}=" do |val|
          send(:delegator_for_setter, association, attr, val)
        end
      end
    end
  end

  def delegator_for(association, attr, *args)
    raise if self.class.column_names.include?(attr.to_s)
    send("#{association}=", self.class.reflect_on_association(association).klass.new) if send(association).nil?
    if args.empty?
      send(association).send(attr)
    else
      send(association).send(attr, *args)
    end
  end

  def delegator_for_setter(association, attr, val)
    raise if self.class.column_names.include?(attr.to_s)
    send("#{association}=", self.class.reflect_on_association(association).klass.new) if send(association).nil?
    send(association).send("#{attr}=", val)
  end
  protected :delegator_for
  protected :delegator_for_setter
end

ActiveRecord::Base.send :include, DelegateBelongsTo
