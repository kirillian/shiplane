require 'facets/hash/deep_merge'

class Hash
  def whitelist(*keymaps)
    self.dup.whitelist!(*keymaps)
  end

  def whitelist!(*keymaps)
    keymaps.map do |map|
      deep_subset(map)
    end.inject(&:deep_merge)
  end

  def deep_subset(keymap)
    self.dup.deep_subset!(keymap)
  end

  def deep_subset!(keymap)
    keypath_keys = keymap.split('.')
    return {} unless keypath_keys.size >= 1

    deepest_subset = { keypath_keys.last => dig(*keypath_keys) }

    keypath_keys[0..-2].reverse.inject(deepest_subset)do |accum, key|
      accum = { key => accum }
    end
  end

  def blacklist(keymap)
    self.dup.blacklist!(keymap)
  end

  def blacklist!(keymap, parentparts = nil)
    keypart, *rest = keymap.split(".")
    keychain = [parentparts, keypart].compact.join(".")

    self.each do |k, v|
      v.blacklist!(Array(rest).join("."), keychain) if v.is_a?(Hash) && k.to_s == keypart.to_s
      self.delete(k) if k.to_s == keypart.to_s && rest.empty?
    end
  end
end

class Array
  def pad(pad_length, character = nil)
    return self if size >= pad_length
    self + [character] * (pad_length - size)
  end
end
