class ProtectedMethodClass
  def initialize(foo)

  end

  def talk(blab)
    sku.foo = doo
  end

protected
  def whisper(mutter)
    foo.doo = sku
  end

private
  def think(mentate)
    doo.sku = foo
  end
end
