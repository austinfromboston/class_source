class SideEffectClass
  @@active = true

  def self.deactivate!
    @@active = false
  end

  def self.active?
    @@active
  end
end
