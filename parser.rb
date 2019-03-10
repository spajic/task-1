class Parser
  USER_PREFIX = 'user,'.freeze
  SESSION_PREFIX = 'session,'.freeze
  COMMA_SEPARATOR = ','.freeze
  SESSION_ATTRIBUTES = %i[user_id session_id browser time date].freeze
  USER_ATTRIBUTES = %i[id first_name last_name age].freeze

  def self.parse_user(user)
    result = {}
    index = 0
    user.delete_prefix!(USER_PREFIX).split(COMMA_SEPARATOR) do |atrribute|
      result[USER_ATTRIBUTES[index]] = atrribute
      index += 1
    end

    result
  end

  def self.parse_session(session)
    result = {}
    index = 0
    session.delete_prefix!(SESSION_PREFIX).split(COMMA_SEPARATOR) do |atrribute|
      result[SESSION_ATTRIBUTES[index]] = atrribute
      index += 1
    end

    result
  end
end
