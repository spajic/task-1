class User
  attr_reader :attributes, :sessions

  def initialize(attributes:)
    @attributes = attributes
    @sessions = []
  end
end
