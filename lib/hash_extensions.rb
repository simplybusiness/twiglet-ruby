# frozen_string_literal: true

module HashExtensions
  def to_nested
    self unless contains_dotted_key?

    keys.reduce({}) do |nested, key|
      nested.deep_merge(build_nested_object(key, self[key]))
    end
  end

  def deep_merge(hash_to_merge)
    merger = proc { |_, val1, val2| val1.is_a?(Hash) && val2.is_a?(Hash) ? val1.merge(val2, &merger) : val2 }
    merge(hash_to_merge, &merger)
  end

  private

  def contains_dotted_key?
    keys.any? { |x| x.to_s.include?('.') }
  end

  def build_nested_object(key, val)
    key.to_s
       .split('.')
       .reverse
       .reduce(val) { |nested, key_part| { key_part.to_sym => nested } }
  end
end
