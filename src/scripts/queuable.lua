local QueuableClass = Glu.glass.register({
  name = "queuable",
  class_name = "QueuableClass",
  dependencies = { "table" },
  adopts = {
    table = {
      methods = { "push", "shift", "pop", "unshift" }
    }
  },
  setup = function(___, self)
    self.stack = {}
  end
})
