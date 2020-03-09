# frozen_string_literal: true

# https://stackoverflow.com/a/11105831
class Hash
  # Returns a hash that includes everything but the given keys.
  #   hash = { a: true, b: false, c: nil}
  #   hash.except(:c) # => { a: true, b: false}
  #   hash # => { a: true, b: false, c: nil}
  #
  # This is useful for limiting a set of parameters to everything but a few known toggles:
  #   @person.update(params[:person].except(:admin))
  def except(keys)
    dup.except!(keys)
  end

  # Replaces the hash without the given keys.
  #   hash = { a: true, b: false, c: nil}
  #   hash.except!(:c) # => { a: true, b: false}
  #   hash # => { a: true, b: false }
  def except!(keys)
    keys.each { |key| delete(key) }
    self
  end

  # Returns a Hash with all keys in +keys+ and deletes all other keys.
  def only(keys)
    dup.only!(keys)
  end

  # Returns the Hash with all keys in +keys+ and deletes all other keys.
  def only!(keys)
    del_keys = self.keys
    del_keys.delete_if { |k| keys.include?(k) }.each { |k| delete(k)}
    self
  end
end
