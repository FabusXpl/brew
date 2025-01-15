# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `SystemCommand`.
# Please instead update this file by running `bin/tapioca dsl SystemCommand`.


class SystemCommand
  sig { returns(T::Boolean) }
  def must_succeed?; end

  sig { returns(T::Boolean) }
  def reset_uid?; end

  sig { returns(T::Boolean) }
  def sudo?; end

  sig { returns(T::Boolean) }
  def sudo_as_root?; end
end
