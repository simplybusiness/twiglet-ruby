# frozen_string_literal: true

module ElasticCommonSchema
  def to_nested(log)
    log unless contains_dotted_key?(log)

    log.keys.reduce({}) do |nested, key|
      deep_merge(nested, build_nested_object(key, log[key]))
    end
  end

  def deep_merge(hash1, hash2)
    merger = proc { |_, val1, val2| val1.is_a?(Hash) && val2.is_a?(Hash) ? val1.merge(val2, &merger) : val2 }
    hash1.merge(hash2, &merger)
  end

  private

  def contains_dotted_key?(log)
    log.keys.any? { |x| x.to_s.include?('.') }
  end

  def build_nested_object(key, val)
    key.to_s
       .split('.')
       .reverse
       .reduce(val) { |nested, key_part| Hash[key_part.to_sym, nested] }
  end
end
