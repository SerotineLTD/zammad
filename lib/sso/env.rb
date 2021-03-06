# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Sso::Env
  def self.check( _params, _config_item )

    # try to find user based on login
#    if ENV['REMOTE_USER']
#      user = User.where( login: ENV['REMOTE_USER'], active: true ).first
    if _params['REMOTE_USER']
      user = User.where( login: _params['REMOTE_USER'].downcase, active: true ).first
      return user if user
    end

  #  if ENV['HTTP_REMOTE_USER']
  #    user = User.where( login: ENV['HTTP_REMOTE_USER'], active: true ).first
    if _params['HTTP_REMOTE_USER']
      user = User.where( login: _params['HTTP_REMOTE_USER'].downcase, active: true ).first
      return user if user
    end

    false
  end
end
