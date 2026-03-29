# frozen_string_literal: true

# Ruby 3.2+ removed Object#tainted?; Liquid 4.0.3 (pinned by github-pages) still uses it.
# Safe no-ops: Jekyll does not rely on Ruby's taint / $SAFE model.
unless "".respond_to?(:tainted?)
  class Object
    def tainted?
      false
    end

    def untaint
      self
    end
  end
end
